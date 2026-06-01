import AppKit
import CryptoKit
import Foundation

enum ClipboardPayload {
    case text(String)
    case image(NSImage, Data)

    var preview: String {
        switch self {
        case .text(let text):
            return text.replacingOccurrences(of: "\n", with: " ")
        case .image:
            return "Изображение"
        }
    }

    var searchText: String {
        preview.lowercased()
    }
}

struct ClipboardHistoryItem: Identifiable {
    let id: String
    let payload: ClipboardPayload
    let createdAt: Date
}

@MainActor
final class ClipboardHistoryStore {
    static let shared = ClipboardHistoryStore()

    private let limitKey = "clipboardHistoryLimit"
    private let pasteboard = NSPasteboard.general
    private var timer: Timer?
    private var lastChangeCount: Int
    private(set) var items: [ClipboardHistoryItem] = []
    var onChange: (() -> Void)?

    var limit: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: limitKey)
            return saved == 0 ? 10 : min(100, max(10, saved))
        }
        set {
            let clamped = min(100, max(10, newValue))
            UserDefaults.standard.set(clamped, forKey: limitKey)
            trim()
            onChange?()
        }
    }

    private init() {
        lastChangeCount = pasteboard.changeCount
    }

    func startMonitoring() {
        captureCurrentPasteboard()
        timer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollPasteboard()
            }
        }
    }

    func clear() {
        items.removeAll()
        onChange?()
    }

    func filtered(by query: String) -> [ClipboardHistoryItem] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return items
        }
        return items.filter { $0.payload.searchText.contains(normalized) }
    }

    func copyToPasteboard(_ item: ClipboardHistoryItem) {
        pasteboard.clearContents()

        switch item.payload {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let image, let data):
            pasteboard.setData(data, forType: .tiff)
            pasteboard.writeObjects([image])
        }

        lastChangeCount = pasteboard.changeCount
        add(item.payload)
    }

    private func pollPasteboard() {
        guard pasteboard.changeCount != lastChangeCount else {
            return
        }
        lastChangeCount = pasteboard.changeCount
        captureCurrentPasteboard()
    }

    private func captureCurrentPasteboard() {
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            add(.text(text))
            return
        }

        if let tiffData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: tiffData) {
            add(.image(image, tiffData))
            return
        }

        if let pngData = pasteboard.data(forType: NSPasteboard.PasteboardType("public.png")),
           let image = NSImage(data: pngData),
           let tiffData = image.tiffRepresentation {
            add(.image(image, tiffData))
            return
        }
    }

    private func add(_ payload: ClipboardPayload) {
        let id = fingerprint(payload)
        items.removeAll { $0.id == id }
        items.insert(ClipboardHistoryItem(id: id, payload: payload, createdAt: Date()), at: 0)
        trim()
        onChange?()
    }

    private func trim() {
        if items.count > limit {
            items = Array(items.prefix(limit))
        }
    }

    private func fingerprint(_ payload: ClipboardPayload) -> String {
        switch payload {
        case .text(let text):
            return "text:" + sha256(Data(text.utf8))
        case .image(_, let data):
            return "image:" + sha256(data)
        }
    }

    private func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
