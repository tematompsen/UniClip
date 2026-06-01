import AppKit
import Carbon
import Foundation

struct KeyboardShortcut {
    let keyCode: UInt32
    let carbonModifiers: UInt32
    let displayName: String

    private static let keyCodeKey = "windowShortcutKeyCode"
    private static let modifiersKey = "windowShortcutModifiers"
    private static let displayNameKey = "windowShortcutDisplayName"

    static var defaultShortcut: KeyboardShortcut {
        KeyboardShortcut(keyCode: 9, carbonModifiers: UInt32(optionKey), displayName: "⌥ V")
    }

    static func load() -> KeyboardShortcut {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: keyCodeKey) != nil,
              defaults.object(forKey: modifiersKey) != nil else {
            return defaultShortcut
        }

        let keyCode = UInt32(defaults.integer(forKey: keyCodeKey))
        let modifiers = UInt32(defaults.integer(forKey: modifiersKey))
        let display = defaults.string(forKey: displayNameKey) ?? defaultShortcut.displayName
        return KeyboardShortcut(keyCode: keyCode, carbonModifiers: modifiers, displayName: display)
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(Int(keyCode), forKey: Self.keyCodeKey)
        defaults.set(Int(carbonModifiers), forKey: Self.modifiersKey)
        defaults.set(displayName, forKey: Self.displayNameKey)
    }

    static func from(event: NSEvent) -> KeyboardShortcut? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var modifiers: UInt32 = 0
        var symbols: [String] = []

        if flags.contains(.control) {
            modifiers |= UInt32(controlKey)
            symbols.append("⌃")
        }
        if flags.contains(.option) {
            modifiers |= UInt32(optionKey)
            symbols.append("⌥")
        }
        if flags.contains(.shift) {
            modifiers |= UInt32(shiftKey)
            symbols.append("⇧")
        }
        if flags.contains(.command) {
            modifiers |= UInt32(cmdKey)
            symbols.append("⌘")
        }

        guard modifiers != 0 else {
            return nil
        }

        let key = (event.charactersIgnoringModifiers ?? "").uppercased()
        guard !key.isEmpty else {
            return nil
        }

        return KeyboardShortcut(
            keyCode: UInt32(event.keyCode),
            carbonModifiers: modifiers,
            displayName: (symbols + [key]).joined(separator: " ")
        )
    }
}

@MainActor
final class GlobalHotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    var onHotKey: (() -> Void)?

    init() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, _, userData in
            guard let userData else {
                return noErr
            }
            let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            Task { @MainActor in
                manager.onHotKey?()
            }
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
    }

    func register(_ shortcut: KeyboardShortcut) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        var newRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: 0x55434C50, id: 1)
        RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &newRef
        )
        hotKeyRef = newRef
    }
}
