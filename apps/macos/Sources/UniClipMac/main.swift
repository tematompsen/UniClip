import AppKit
import CoreGraphics
import Foundation
import Network

private let protocolVersion = 1
private let serviceType = "_uniclip._tcp."
private let serviceDomain = "local."
private let defaultPort: NWEndpoint.Port = 47191
private let maxMessageBytes = 20 * 1024 * 1024

struct ClipMessage: Codable {
    let protocolVersion: Int
    let clipId: String
    let sourceDeviceId: String
    let sourceDeviceName: String
    let contentType: String
    let createdAt: String
    let ttlSeconds: Int
    let payload: String
}

final class PasteboardWriter: @unchecked Sendable {
    func write(_ message: ClipMessage) throws {
        switch message.contentType {
        case "text/plain":
            try writeText(message.payload)
        case let contentType where contentType.hasPrefix("image/"):
            try writeImage(base64Payload: message.payload, contentType: contentType)
        default:
            throw UniClipError.unsupportedContentType(message.contentType)
        }
    }

    private func writeText(_ text: String) throws {
        DispatchQueue.main.sync {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
    }

    private func writeImage(base64Payload: String, contentType: String) throws {
        guard let rawData = Data(base64Encoded: base64Payload),
              let image = NSImage(data: rawData) else {
            throw UniClipError.invalidMessage
        }

        DispatchQueue.main.sync {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()

            if contentType == "image/png" {
                pasteboard.setData(rawData, forType: NSPasteboard.PasteboardType("public.png"))
            } else if contentType == "image/jpeg" || contentType == "image/jpg" {
                pasteboard.setData(rawData, forType: NSPasteboard.PasteboardType("public.jpeg"))
            }

            if let tiffData = image.tiffRepresentation {
                pasteboard.setData(tiffData, forType: .tiff)
            }
        }
    }
}

enum UniClipError: Error, CustomStringConvertible {
    case invalidMessage
    case unsupportedContentType(String)

    var description: String {
        switch self {
        case .invalidMessage:
            return "Invalid message"
        case .unsupportedContentType(let contentType):
            return "Unsupported content type: \(contentType)"
        }
    }
}

final class UniClipReceiver: @unchecked Sendable {
    private let listener: NWListener
    private let pasteboardWriter: PasteboardWriter
    private var netService: NetService?
    private var seenClipIds = Set<String>()
    private let queue = DispatchQueue(label: "dev.uniclip.mac.receiver")

    init(port: NWEndpoint.Port = defaultPort, pasteboardWriter: PasteboardWriter = PasteboardWriter()) throws {
        self.listener = try NWListener(using: .tcp, on: port)
        self.pasteboardWriter = pasteboardWriter
    }

    func start() {
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }

        listener.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.publishBonjour()
                print("UniClip macOS receiver listening on port \(defaultPort.rawValue)")
            case .failed(let error):
                print("Receiver failed: \(error)")
                exit(1)
            default:
                break
            }
        }

        listener.start(queue: queue)
    }

    private func publishBonjour() {
        let service = NetService(
            domain: serviceDomain,
            type: serviceType,
            name: Host.current().localizedName ?? "UniClip Mac",
            port: Int32(defaultPort.rawValue)
        )

        let txt: [String: Data] = [
            "version": "\(protocolVersion)".data(using: .utf8)!,
            "device": "mac".data(using: .utf8)!,
            "name": (Host.current().localizedName ?? "Mac").data(using: .utf8)!
        ]

        service.setTXTRecord(NetService.data(fromTXTRecord: txt))
        service.publish()
        netService = service
    }

    private func handle(_ connection: NWConnection) {
        connection.stateUpdateHandler = { state in
            if case .failed(let error) = state {
                print("Connection failed: \(error)")
            }
        }

        connection.start(queue: queue)
        receiveMessage(from: connection, buffer: Data())
    }

    private func receiveMessage(from connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 256 * 1024) { [weak self] data, _, isComplete, error in
            if let error {
                print("Receive error: \(error)")
                connection.cancel()
                return
            }

            var nextBuffer = buffer
            if let data {
                nextBuffer.append(data)
            }

            guard nextBuffer.count <= maxMessageBytes else {
                self?.sendAck(to: connection, status: "error", detail: "Payload too large")
                return
            }

            if let newlineIndex = nextBuffer.firstIndex(of: 0x0A) {
                self?.process(nextBuffer[..<newlineIndex], connection: connection)
                return
            }

            if isComplete || data?.isEmpty == true {
                self?.process(nextBuffer, connection: connection)
                return
            }

            self?.receiveMessage(from: connection, buffer: nextBuffer)
        }
    }

    private func process(_ data: Data, connection: NWConnection) {
        do {
            let message = try JSONDecoder().decode(ClipMessage.self, from: data)
            guard message.protocolVersion == protocolVersion else {
                throw UniClipError.invalidMessage
            }

            guard !seenClipIds.contains(message.clipId) else {
                sendAck(to: connection, status: "duplicate")
                return
            }

            seenClipIds.insert(message.clipId)
            try pasteboardWriter.write(message)
            sendAck(to: connection, status: "ok")
            print("Received \(message.contentType) clip from \(message.sourceDeviceName)")
        } catch {
            sendAck(to: connection, status: "error", detail: "\(error)")
            print("Payload rejected: \(error)")
        }
    }

    private func sendAck(to connection: NWConnection, status: String, detail: String? = nil) {
        let payload: [String: String] = {
            if let detail {
                return ["status": status, "detail": detail]
            }
            return ["status": status]
        }()

        guard let data = try? JSONSerialization.data(withJSONObject: payload) else {
            connection.cancel()
            return
        }

        var framed = data
        framed.append(0x0A)

        connection.send(content: framed, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

@MainActor
final class HistoryPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }
}

@MainActor
final class UniClipAppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var receiver: UniClipReceiver?
    private let historyStore = ClipboardHistoryStore.shared
    private var historyController: HistoryPopoverController?
    private var historyPanel: HistoryPanel?
    private var eventMonitor: Any?
    private let hotKeyManager = GlobalHotKeyManager()
    private var previousApplication: NSRunningApplication?
    private var didRequestPostEventAccess = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureHistoryPanel()
        installStatusItem()
        installHotKey()
        historyStore.startMonitoring()
        startReceiver()
    }

    private func configureHistoryPanel() {
        let controller = HistoryPopoverController(store: historyStore)
        controller.onQuit = { [weak self] in
            self?.quit()
        }
        controller.onItemCopied = { [weak self] in
            self?.pasteCopiedItem()
        }
        controller.onShortcutChanged = { [weak self] shortcut in
            self?.hotKeyManager.register(shortcut)
        }
        historyController = controller

        let panel = HistoryPanel(
            contentRect: NSRect(origin: .zero, size: controller.preferredContentSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = controller
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.isReleasedWhenClosed = false
        historyPanel = panel
    }

    private func installHotKey() {
        hotKeyManager.onHotKey = { [weak self] in
            self?.rememberFrontmostApplication()
            self?.togglePopover()
        }
        hotKeyManager.register(KeyboardShortcut.load())
    }

    private func installStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let path = Bundle.main.path(forResource: "StatusBarIconTemplate", ofType: "png"),
               let image = NSImage(contentsOfFile: path) {
                image.isTemplate = true
                image.size = NSSize(width: 20, height: 20)
                button.image = image
            } else {
                button.image = NSImage(
                    systemSymbolName: "doc.on.clipboard",
                    accessibilityDescription: "UniClip"
                )
                button.image?.isTemplate = true
            }
            button.toolTip = "UniClip"
            button.target = self
            button.action = #selector(togglePopover)
        }
        self.statusItem = statusItem
    }

    private func startReceiver() {
        do {
            let receiver = try UniClipReceiver()
            receiver.start()
            self.receiver = receiver
        } catch {
            presentStartupError(error)
        }
    }

    private func presentStartupError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "UniClip failed to start"
        alert.informativeText = "\(error)"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Quit")
        alert.runModal()
        NSApp.terminate(nil)
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else {
            return
        }

        if historyPanel?.isVisible == true {
            closeHistoryPanel()
        } else {
            showHistoryPanel(relativeTo: button)
        }
    }

    private func showHistoryPanel(relativeTo button: NSStatusBarButton) {
        guard let panel = historyPanel else {
            return
        }

        rememberFrontmostApplication()

        let buttonRect = button.convert(button.bounds, to: nil)
        guard let screenRect = button.window?.convertToScreen(buttonRect) else {
            return
        }

        let panelSize = panel.frame.size
        let visibleFrame = button.window?.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        var x = screenRect.midX - panelSize.width / 2
        x = min(max(x, visibleFrame.minX + 8), visibleFrame.maxX - panelSize.width - 8)
        let y = screenRect.minY - panelSize.height - 8

        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.orderFrontRegardless()
        panel.makeKey()
        panel.contentViewController?.view.window?.makeFirstResponder(historyController?.searchFieldForFocus)
        installEventMonitor()
    }

    private func closeHistoryPanel() {
        historyPanel?.orderOut(nil)
        removeEventMonitor()
    }

    private func rememberFrontmostApplication() {
        guard let frontmost = NSWorkspace.shared.frontmostApplication,
              frontmost.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return
        }
        previousApplication = frontmost
    }

    private func pasteCopiedItem() {
        let targetApplication = previousApplication
        closeHistoryPanel()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            guard self.ensurePostEventAccess() else {
                self.presentPastePermissionAlert()
                return
            }

            if #available(macOS 14.0, *) {
                targetApplication?.activate()
            } else {
                targetApplication?.activate(options: [.activateIgnoringOtherApps])
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                self.postPasteShortcut(to: targetApplication)
            }
        }
    }

    private func ensurePostEventAccess() -> Bool {
        if CGPreflightPostEventAccess() {
            return true
        }

        if !didRequestPostEventAccess {
            didRequestPostEventAccess = true
            CGRequestPostEventAccess()
        }

        return CGPreflightPostEventAccess()
    }

    private func presentPastePermissionAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Нужно разрешение для вставки"
        alert.informativeText = "macOS блокирует автоматическую вставку. Разреши UniClip отправлять события клавиатуры в системном запросе, затем выбери фрагмент еще раз."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func postPasteShortcut(to application: NSRunningApplication?) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        if let pid = application?.processIdentifier {
            keyDown?.postToPid(pid)
            keyUp?.postToPid(pid)
            return
        }

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private func installEventMonitor() {
        removeEventMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.closeHistoryPanel()
            }
        }
    }

    private func removeEventMonitor() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = UniClipAppDelegate()
app.delegate = delegate
app.run()
