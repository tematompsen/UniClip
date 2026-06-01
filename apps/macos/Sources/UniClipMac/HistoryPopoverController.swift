import AppKit

@MainActor
final class HistoryPopoverController: NSViewController, NSSearchFieldDelegate {
    private enum Layout {
        static let width: CGFloat = 500
        static let height: CGFloat = 720
        static let inset: CGFloat = 12
        static let contentWidth: CGFloat = 476
        static let rowWidth: CGFloat = 476
        static let scrollHeight: CGFloat = 528
    }

    private let store: ClipboardHistoryStore
    private let searchField = NSSearchField()
    private let scrollView = NSScrollView()
    private let listContainer = FlippedView()
    private let listStack = NSStackView()
    private let settingsStack = NSStackView()
    private let limitLabel = NSTextField(labelWithString: "")
    private let shortcutButton = ShortcutRecorderButton()
    private var query = ""
    var onQuit: (() -> Void)?
    var onItemCopied: (() -> Void)?
    var onShortcutChanged: ((KeyboardShortcut) -> Void)?

    init(store: ClipboardHistoryStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = NSSize(width: Layout.width, height: Layout.height)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: Layout.width, height: Layout.height))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        buildView()
        store.onChange = { [weak self] in
            self?.reload()
        }
        reload()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(searchField)
    }

    private func buildView() {
        let root = NSStackView()
        root.orientation = .vertical
        root.spacing = 8
        root.alignment = .leading
        root.translatesAutoresizingMaskIntoConstraints = false
        root.edgeInsets = NSEdgeInsets(top: Layout.inset, left: Layout.inset, bottom: Layout.inset, right: Layout.inset)
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            root.topAnchor.constraint(equalTo: view.topAnchor),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let header = NSStackView()
        header.orientation = .horizontal
        header.spacing = 12
        header.alignment = .centerY
        header.translatesAutoresizingMaskIntoConstraints = false
        header.widthAnchor.constraint(equalToConstant: Layout.contentWidth).isActive = true

        let title = NSTextField(labelWithString: "UniClip")
        title.font = .systemFont(ofSize: 13, weight: .regular)
        title.setContentHuggingPriority(.required, for: .horizontal)
        header.addArrangedSubview(title)

        searchField.placeholderString = "начните печатать для поиска..."
        searchField.delegate = self
        searchField.font = .systemFont(ofSize: 12, weight: .regular)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.heightAnchor.constraint(equalToConstant: 24).isActive = true
        header.addArrangedSubview(searchField)
        root.addArrangedSubview(header)

        listStack.orientation = .vertical
        listStack.spacing = 4
        listStack.alignment = .leading
        listStack.translatesAutoresizingMaskIntoConstraints = true

        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = listContainer
        root.addArrangedSubview(scrollView)
        scrollView.widthAnchor.constraint(equalToConstant: Layout.contentWidth).isActive = true
        scrollView.heightAnchor.constraint(equalToConstant: Layout.scrollHeight).isActive = true
        listContainer.addSubview(listStack)

        buildSettings(root)
        buildFooter(root)
    }

    private func buildSettings(_ root: NSStackView) {
        settingsStack.orientation = .vertical
        settingsStack.spacing = 8
        settingsStack.isHidden = true
        settingsStack.alignment = .leading
        settingsStack.translatesAutoresizingMaskIntoConstraints = false
        settingsStack.widthAnchor.constraint(equalToConstant: Layout.contentWidth).isActive = true

        limitLabel.font = .systemFont(ofSize: 10, weight: .regular)
        settingsStack.addArrangedSubview(limitLabel)

        let slider = NSSlider(value: Double(store.limit), minValue: 10, maxValue: 100, target: self, action: #selector(limitChanged(_:)))
        slider.numberOfTickMarks = 10
        slider.allowsTickMarkValuesOnly = true
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.widthAnchor.constraint(equalToConstant: Layout.contentWidth).isActive = true
        settingsStack.addArrangedSubview(slider)

        let shortcutRow = NSStackView()
        shortcutRow.orientation = .horizontal
        shortcutRow.spacing = 8
        shortcutRow.alignment = .centerY

        let shortcutLabel = NSTextField(labelWithString: "Вызов окна")
        shortcutLabel.font = .systemFont(ofSize: 10, weight: .regular)
        shortcutRow.addArrangedSubview(shortcutLabel)

        shortcutButton.shortcut = KeyboardShortcut.load()
        shortcutButton.onShortcutChanged = { [weak self] shortcut in
            shortcut.save()
            self?.onShortcutChanged?(shortcut)
        }
        shortcutRow.addArrangedSubview(shortcutButton)
        settingsStack.addArrangedSubview(shortcutRow)

        root.addArrangedSubview(settingsStack)
        updateLimitLabel()
    }

    private func buildFooter(_ root: NSStackView) {
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.widthAnchor.constraint(equalToConstant: Layout.contentWidth).isActive = true
        root.addArrangedSubview(separator)

        let footer = NSStackView()
        footer.orientation = .vertical
        footer.spacing = 8
        footer.alignment = .leading
        footer.translatesAutoresizingMaskIntoConstraints = false
        footer.widthAnchor.constraint(equalToConstant: Layout.contentWidth).isActive = true
        root.addArrangedSubview(footer)

        footer.addArrangedSubview(actionButton("Очистить всё", action: #selector(clearHistory)))
        footer.addArrangedSubview(actionButton("Настройки...", action: #selector(toggleSettings)))
        footer.addArrangedSubview(actionButton("О приложении", action: #selector(showAbout)))
        footer.addArrangedSubview(actionButton("Завершить", action: #selector(quit)))
    }

    private func actionButton(_ title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.isBordered = false
        button.alignment = .left
        button.font = .systemFont(ofSize: 11, weight: .regular)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: Layout.contentWidth).isActive = true
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return button
    }

    private func reload() {
        listStack.arrangedSubviews.forEach {
            listStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let items = store.filtered(by: query)
        if items.isEmpty {
            let empty = NSTextField(labelWithString: "История пуста")
            empty.textColor = .secondaryLabelColor
            empty.font = .systemFont(ofSize: 11, weight: .regular)
            empty.frame = NSRect(x: 8, y: 8, width: Layout.rowWidth, height: 28)
            listStack.addArrangedSubview(empty)
            updateListFrames(rowHeights: [28])
            return
        }

        var heights: [CGFloat] = []
        for item in items {
            let height = itemHeight(item)
            heights.append(height)
            listStack.addArrangedSubview(row(for: item, width: Layout.rowWidth))
        }
        updateListFrames(rowHeights: heights)
    }

    private func updateListFrames(rowHeights: [CGFloat]) {
        let totalHeight = max(rowHeights.reduce(0, +) + CGFloat(max(0, rowHeights.count - 1)) * listStack.spacing, scrollView.contentSize.height)
        listContainer.frame = NSRect(x: 0, y: 0, width: Layout.contentWidth, height: totalHeight)
        listStack.frame = NSRect(x: 0, y: 0, width: Layout.contentWidth, height: totalHeight)
        listStack.needsLayout = true
    }

    private func row(for item: ClipboardHistoryItem, width: CGFloat) -> NSView {
        let button = HistoryRowButton(item: item)
        button.target = self
        button.action = #selector(copyHistoryItem(_:))
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: width).isActive = true
        button.heightAnchor.constraint(equalToConstant: itemHeight(item)).isActive = true

        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false
        row.edgeInsets = NSEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        button.addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 8),
            row.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -8),
            row.topAnchor.constraint(equalTo: button.topAnchor, constant: 4),
            row.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -4)
        ])

        switch item.payload {
        case .text(let text):
            let label = NSTextField(labelWithString: text.replacingOccurrences(of: "\n", with: " "))
            label.font = .systemFont(ofSize: 11, weight: .regular)
            label.lineBreakMode = .byTruncatingMiddle
            button.highlightTextFields.append(label)
            row.addArrangedSubview(label)
        case .image(let image, _):
            let imageView = NSImageView()
            imageView.image = image
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: 54).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 54).isActive = true
            row.addArrangedSubview(imageView)

            let label = NSTextField(labelWithString: "Изображение")
            label.textColor = .secondaryLabelColor
            label.font = .systemFont(ofSize: 11, weight: .regular)
            button.highlightTextFields.append(label)
            row.addArrangedSubview(label)
        }

        return button
    }

    private func itemHeight(_ item: ClipboardHistoryItem) -> CGFloat {
        switch item.payload {
        case .text:
            return 40
        case .image:
            return 72
        }
    }

    func controlTextDidChange(_ obj: Notification) {
        query = searchField.stringValue
        reload()
    }

    @objc private func copyHistoryItem(_ sender: HistoryRowButton) {
        store.copyToPasteboard(sender.item)
        onItemCopied?()
    }

    @objc private func clearHistory() {
        store.clear()
    }

    @objc private func toggleSettings() {
        settingsStack.isHidden.toggle()
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        onQuit?()
    }

    @objc private func limitChanged(_ sender: NSSlider) {
        store.limit = Int(sender.doubleValue.rounded())
        updateLimitLabel()
    }

    private func updateLimitLabel() {
        limitLabel.stringValue = "Сохранять последних: \(store.limit)"
    }
}

@MainActor
final class HistoryRowButton: NSButton {
    let item: ClipboardHistoryItem
    var highlightTextFields: [NSTextField] = []
    private var trackingAreaRef: NSTrackingArea?

    init(item: ClipboardHistoryItem) {
        self.item = item
        super.init(frame: .zero)
        title = ""
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let area = NSTrackingArea(rect: bounds, options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect], owner: self)
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func mouseEntered(with event: NSEvent) {
        setHover(true)
    }

    override func mouseExited(with event: NSEvent) {
        setHover(false)
    }

    private func setHover(_ isHovering: Bool) {
        layer?.backgroundColor = isHovering ? NSColor.controlAccentColor.cgColor : NSColor.clear.cgColor
        highlightTextFields.forEach {
            $0.textColor = isHovering ? .white : .labelColor
        }
    }
}

final class FlippedView: NSView {
    override var isFlipped: Bool {
        true
    }
}

@MainActor
final class ShortcutRecorderButton: NSButton {
    var shortcut: KeyboardShortcut = .defaultShortcut {
        didSet {
            title = shortcut.displayName
        }
    }
    var onShortcutChanged: ((KeyboardShortcut) -> Void)?
    private var isRecording = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isBordered = false
        font = .systemFont(ofSize: 11, weight: .regular)
        target = self
        action = #selector(startRecording)
        title = shortcut.displayName
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    @objc private func startRecording() {
        isRecording = true
        title = "Нажмите сочетание"
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        guard let newShortcut = KeyboardShortcut.from(event: event) else {
            NSSound.beep()
            return
        }

        isRecording = false
        shortcut = newShortcut
        onShortcutChanged?(newShortcut)
    }
}
