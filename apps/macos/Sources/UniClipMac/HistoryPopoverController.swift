import AppKit

@MainActor
final class HistoryPopoverController: NSViewController, NSSearchFieldDelegate {
    private let store: ClipboardHistoryStore
    private let searchField = NSSearchField()
    private let scrollView = NSScrollView()
    private let listStack = NSStackView()
    private let settingsStack = NSStackView()
    private let limitLabel = NSTextField(labelWithString: "")
    private var query = ""
    var onQuit: (() -> Void)?

    init(store: ClipboardHistoryStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = NSSize(width: 560, height: 680)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 680))
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
        root.spacing = 12
        root.translatesAutoresizingMaskIntoConstraints = false
        root.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
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

        let title = NSTextField(labelWithString: "UniClip")
        title.font = .boldSystemFont(ofSize: 22)
        title.setContentHuggingPriority(.required, for: .horizontal)
        header.addArrangedSubview(title)

        searchField.placeholderString = "начните печатать для поиска..."
        searchField.delegate = self
        searchField.font = .systemFont(ofSize: 18)
        header.addArrangedSubview(searchField)
        root.addArrangedSubview(header)

        listStack.orientation = .vertical
        listStack.spacing = 4
        listStack.alignment = .leading

        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.documentView = listStack
        root.addArrangedSubview(scrollView)
        scrollView.heightAnchor.constraint(equalToConstant: 500).isActive = true

        buildSettings(root)
        buildFooter(root)
    }

    private func buildSettings(_ root: NSStackView) {
        settingsStack.orientation = .vertical
        settingsStack.spacing = 8
        settingsStack.isHidden = true

        limitLabel.font = .systemFont(ofSize: 13, weight: .medium)
        settingsStack.addArrangedSubview(limitLabel)

        let slider = NSSlider(value: Double(store.limit), minValue: 10, maxValue: 100, target: self, action: #selector(limitChanged(_:)))
        slider.numberOfTickMarks = 10
        slider.allowsTickMarkValuesOnly = true
        settingsStack.addArrangedSubview(slider)

        root.addArrangedSubview(settingsStack)
        updateLimitLabel()
    }

    private func buildFooter(_ root: NSStackView) {
        let separator = NSBox()
        separator.boxType = .separator
        root.addArrangedSubview(separator)

        let footer = NSStackView()
        footer.orientation = .vertical
        footer.spacing = 8
        root.addArrangedSubview(footer)

        footer.addArrangedSubview(actionButton("Очистить всё", action: #selector(clearHistory)))
        footer.addArrangedSubview(actionButton("Настройки...", action: #selector(toggleSettings)))
        footer.addArrangedSubview(actionButton("О приложении", action: #selector(showAbout)))
        footer.addArrangedSubview(actionButton("Завершить", action: #selector(quit)))
    }

    private func actionButton(_ title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .inline
        button.alignment = .left
        button.font = .systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
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
            empty.font = .systemFont(ofSize: 16)
            listStack.addArrangedSubview(empty)
            return
        }

        for (index, item) in items.enumerated() {
            listStack.addArrangedSubview(row(for: item, shortcut: index < 9 ? "⇧⌘ \(index + 1)" : nil))
        }
    }

    private func row(for item: ClipboardHistoryItem, shortcut: String?) -> NSView {
        let button = HistoryRowButton(item: item)
        button.target = self
        button.action = #selector(copyHistoryItem(_:))
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 520).isActive = true
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
            label.font = .systemFont(ofSize: 16, weight: .semibold)
            label.lineBreakMode = .byTruncatingMiddle
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
            label.font = .systemFont(ofSize: 15, weight: .medium)
            row.addArrangedSubview(label)
        }

        if let shortcut {
            let shortcutLabel = NSTextField(labelWithString: shortcut)
            shortcutLabel.textColor = .secondaryLabelColor
            shortcutLabel.font = .monospacedSystemFont(ofSize: 15, weight: .medium)
            shortcutLabel.setContentHuggingPriority(.required, for: .horizontal)
            row.addArrangedSubview(shortcutLabel)
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

    init(item: ClipboardHistoryItem) {
        self.item = item
        super.init(frame: .zero)
        title = ""
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
