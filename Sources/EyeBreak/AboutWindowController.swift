import AppKit

class AboutWindowController: NSWindowController {

    private static var shared: AboutWindowController?

    static func show() {
        if shared == nil { shared = AboutWindowController() }
        shared?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Init

    init() {
        let win = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 390),
            styleMask:   [.titled, .closable, .fullSizeContentView],
            backing:     .buffered,
            defer:       false
        )
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isMovableByWindowBackground = true
        win.center()
        win.title = "About EyeBreak"
        super.init(window: win)
        buildContent()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    private func buildContent() {
        guard let view = window?.contentView else { return }
        view.wantsLayer = true

        // ── Gradient background: deep navy → near-black
        let grad = CAGradientLayer()
        grad.frame = view.bounds
        grad.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        grad.colors  = [
            NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.16, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.02, green: 0.03, blue: 0.06, alpha: 1).cgColor,
        ]
        grad.startPoint = CGPoint(x: 0.5, y: 0)
        grad.endPoint   = CGPoint(x: 0.5, y: 1)
        view.layer?.addSublayer(grad)

        // ── Eye icon (SF Symbol, large)
        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        let symConfig = NSImage.SymbolConfiguration(pointSize: 52, weight: .ultraLight)
        if let img = NSImage(systemSymbolName: "eye", accessibilityDescription: "EyeBreak") {
            iconView.image = img.withSymbolConfiguration(symConfig)
        }
        iconView.contentTintColor = NSColor(calibratedRed: 0.45, green: 0.72, blue: 1.0, alpha: 1)
        view.addSubview(iconView)

        // ── App name
        let nameLabel = label("EyeBreak", size: 28, weight: .thin, color: .white)
        view.addSubview(nameLabel)

        // ── Version (secret: click 5× to enter dev code)
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNum = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let versionLabel = TapTextField(
            labelWithString: "Version \(version) (\(buildNum))")
        versionLabel.font      = NSFont.systemFont(ofSize: 12, weight: .light)
        versionLabel.textColor = NSColor.white.withAlphaComponent(0.40)
        versionLabel.alignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.onFiveTaps = { [weak self] in self?.promptDevCode() }
        view.addSubview(versionLabel)

        // ── Tagline
        let tagline = label("The 20-20-20 rule for eye health.",
                             size: 13, weight: .light,
                             color: NSColor.white.withAlphaComponent(0.65))
        view.addSubview(tagline)

        // ── Description
        let desc = label(
            "Every 20 minutes, look at something 20 feet away\nfor 20 seconds. Pauses automatically during calls.",
            size: 12, weight: .ultraLight,
            color: NSColor.white.withAlphaComponent(0.50)
        )
        (desc.cell as? NSTextFieldCell)?.wraps = true
        desc.maximumNumberOfLines = 3
        desc.preferredMaxLayoutWidth = 300
        view.addSubview(desc)

        // ── Trial / purchase status
        let trial = TrialManager.shared
        let statusText: String
        let statusColor: NSColor
        if trial.isPurchased {
            statusText  = "✓  Licensed"
            statusColor = NSColor(calibratedRed: 0.35, green: 0.85, blue: 0.55, alpha: 1)
        } else if trial.isTrialActive {
            statusText  = "Free trial · \(trial.daysRemaining) day\(trial.daysRemaining == 1 ? "" : "s") remaining"
            statusColor = NSColor(calibratedRed: 0.95, green: 0.78, blue: 0.30, alpha: 1)
        } else {
            statusText  = "Trial expired · Purchase to continue"
            statusColor = NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.40, alpha: 1)
        }
        let statusLabel = label(statusText, size: 11, weight: .regular, color: statusColor)
        view.addSubview(statusLabel)

        // ── Author / links
        let authorLabel = label("by Vikas Anand", size: 11, weight: .light,
                                color: NSColor.white.withAlphaComponent(0.45))
        view.addSubview(authorLabel)

        let websiteButton = linkButton("vikasanand.com", url: "https://vikasanand.com")
        view.addSubview(websiteButton)

        let emailButton = linkButton("sakivva@gmail.com", url: "mailto:sakivva@gmail.com")
        view.addSubview(emailButton)

        // ── Copyright
        let year = Calendar.current.component(.year, from: Date())
        let copy = label("© \(year) Vikas Anand",
                         size: 10, weight: .ultraLight,
                         color: NSColor.white.withAlphaComponent(0.28))
        view.addSubview(copy)

        // ── Constraints
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 44),

            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),

            versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            versionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),

            tagline.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tagline.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 18),

            desc.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            desc.topAnchor.constraint(equalTo: tagline.bottomAnchor, constant: 8),
            desc.widthAnchor.constraint(lessThanOrEqualToConstant: 300),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: desc.bottomAnchor, constant: 18),

            authorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authorLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 18),

            websiteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            websiteButton.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 6),

            emailButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailButton.topAnchor.constraint(equalTo: websiteButton.bottomAnchor, constant: 4),

            copy.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            copy.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
        ])
    }

    // MARK: - Helpers

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let f = NSTextField(labelWithString: text)
        f.font      = NSFont.systemFont(ofSize: size, weight: weight)
        f.textColor = color
        f.alignment = .center
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }

    private func linkButton(_ title: String, url: String) -> NSButton {
        let btn = NSButton(title: title, target: self, action: #selector(openLink(_:)))
        btn.isBordered      = false
        btn.font            = NSFont.systemFont(ofSize: 11, weight: .light)
        btn.contentTintColor = NSColor(calibratedRed: 0.45, green: 0.72, blue: 1.0, alpha: 0.80)
        btn.identifier      = NSUserInterfaceItemIdentifier(url)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    @objc private func openLink(_ sender: NSButton) {
        guard let urlString = sender.identifier?.rawValue,
              let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Dev bypass

    private func promptDevCode() {
        guard let win = window else { return }
        let alert = NSAlert()
        alert.messageText    = "Developer Access"
        alert.informativeText = "Enter developer code to unlock:"
        alert.addButton(withTitle: "Unlock")
        alert.addButton(withTitle: "Cancel")

        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.placeholderString = "Code"
        alert.accessoryView = field

        alert.beginSheetModal(for: win) { response in
            guard response == .alertFirstButtonReturn else { return }
            if field.stringValue == "VIKAS-EYEBREAK-DEV" {
                TrialManager.shared.isPurchased = true
                let ok = NSAlert()
                ok.messageText = "Unlocked"
                ok.informativeText = "Developer mode active. Trial removed."
                ok.runModal()
            }
        }
    }
}

// MARK: - Tap-counting label

private class TapTextField: NSTextField {
    var onFiveTaps: (() -> Void)?
    private var count = 0

    override func mouseDown(with event: NSEvent) {
        count += 1
        if count >= 5 {
            count = 0
            onFiveTaps?()
        }
    }
}
