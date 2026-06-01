import AppKit
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
final class UniClipAppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var receiver: UniClipReceiver?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installStatusMenu()
        startReceiver()
    }

    private func installStatusMenu() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let path = Bundle.main.path(forResource: "StatusBarIconTemplate", ofType: "png"),
               let image = NSImage(contentsOfFile: path) {
                image.isTemplate = true
                button.image = image
            } else {
                button.image = NSImage(
                    systemSymbolName: "doc.on.clipboard",
                    accessibilityDescription: "UniClip"
                )
                button.image?.isTemplate = true
            }
            button.toolTip = "UniClip"
        }

        let menu = NSMenu()
        let titleItem = NSMenuItem(title: "UniClip", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Закрыть", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
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

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = UniClipAppDelegate()
app.delegate = delegate
app.run()
