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
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 370),
            styleMask:   [.titled, .closable, .fullSizeContentView],
            backing:     .buffered,
            defer:       false
        )
        win.titlebarAppearsTransparent = true
        win.titleVisibility            = .hidden
        win.isMovableByWindowBackground = true
        win.appearance = NSAppearance(named: .darkAqua)
        win.center()
        win.title = "About EyeBreak"
        super.init(window: win)
        buildContent()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    private func buildContent() {
        guard let view = window?.contentView else { return }
        let theme = EmberTheme.dark
        view.wantsLayer = true
        view.layer?.backgroundColor = theme.bg.cgColor

        // Subtle top-glow: amber radial from top-centre
        let glowLayer = CAGradientLayer()
        glowLayer.type        = .radial
        glowLayer.colors      = [theme.accent.withAlphaComponent(0.10).cgColor, NSColor.clear.cgColor]
        glowLayer.startPoint  = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint    = CGPoint(x: 1.0, y: 1.0)
        glowLayer.frame       = CGRect(x: 340/2 - 160, y: 370 - 120, width: 320, height: 200)
        view.layer?.addSublayer(glowLayer)

        // ── Eye glyph (custom Ember version)
        let eye = EyeGlyphView(glyphSize: 44, color: theme.accent)
        view.addSubview(eye)

        // ── App name
        let nameLabel = emberLabel("EyeBreak", size: 26, weight: .light, color: theme.text)
        view.addSubview(nameLabel)

        // ── Version (secret: 5 taps → dev code)
        let version  = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0"
        let buildNum = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let versionLabel = TapTextField(labelWithString: "v\(version) (\(buildNum))")
        versionLabel.font      = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        versionLabel.textColor = theme.textDim
        versionLabel.alignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.onFiveTaps = { [weak self] in self?.promptDevCode() }
        view.addSubview(versionLabel)

        // ── Divider
        let divLine = divider(theme: theme)
        view.addSubview(divLine)

        // ── Tagline
        let tagline = emberLabel("The 20-20-20 rule for eye health.",
                                  size: 12, weight: .regular, color: theme.textMuted)
        view.addSubview(tagline)

        // ── Description
        let desc = emberLabel(
            "Every 20 minutes, look at something\n20 feet away for 20 seconds.",
            size: 11, weight: .regular, color: theme.textDim)
        desc.maximumNumberOfLines    = 3
        desc.preferredMaxLayoutWidth = 280
        (desc.cell as? NSTextFieldCell)?.wraps = true
        view.addSubview(desc)

        // ── Status
        let trial = TrialManager.shared
        let (statusText, statusColor): (String, NSColor)
        if trial.isPurchased {
            statusText  = "✓  Licensed"
            statusColor = NSColor(calibratedRed: 0.35, green: 0.85, blue: 0.55, alpha: 1)
        } else if trial.isTrialActive {
            statusText  = "Free trial · \(trial.daysRemaining) day\(trial.daysRemaining == 1 ? "" : "s") left"
            statusColor = theme.accent
        } else {
            statusText  = "Trial expired · Purchase to continue"
            statusColor = NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.40, alpha: 1)
        }
        let statusLabel = emberLabel(statusText, size: 11, weight: .medium, color: statusColor)
        view.addSubview(statusLabel)

        // ── Author / links
        let authorLabel = emberLabel("by Vikas Anand", size: 11, weight: .regular, color: theme.textDim)
        view.addSubview(authorLabel)

        let websiteBtn = linkButton("vikasanand.com",   url: "https://vikasanand.com", theme: theme)
        let emailBtn   = linkButton("sakivva@gmail.com", url: "mailto:sakivva@gmail.com", theme: theme)
        view.addSubview(websiteBtn)
        view.addSubview(emailBtn)

        // ── Copyright
        let year = Calendar.current.component(.year, from: Date())
        let copy = emberLabel("© \(year) Vikas Anand", size: 10, weight: .regular,
                               color: theme.textDim.withAlphaComponent(0.5))
        view.addSubview(copy)

        // ── Constraints
        NSLayoutConstraint.activate([
            eye.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            eye.topAnchor.constraint(equalTo: view.topAnchor, constant: 48),
            eye.widthAnchor.constraint(equalToConstant: 44),
            eye.heightAnchor.constraint(equalToConstant: 44),

            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: eye.bottomAnchor, constant: 10),

            versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            versionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),

            divLine.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            divLine.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            divLine.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 20),
            divLine.heightAnchor.constraint(equalToConstant: 0.5),

            tagline.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tagline.topAnchor.constraint(equalTo: divLine.bottomAnchor, constant: 18),

            desc.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            desc.topAnchor.constraint(equalTo: tagline.bottomAnchor, constant: 6),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: desc.bottomAnchor, constant: 18),

            authorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authorLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),

            websiteBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            websiteBtn.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 5),

            emailBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailBtn.topAnchor.constraint(equalTo: websiteBtn.bottomAnchor, constant: 3),

            copy.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            copy.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -14),
        ])
    }

    // MARK: - Helpers

    private func emberLabel(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let f = NSTextField(labelWithString: text)
        f.font      = NSFont.systemFont(ofSize: size, weight: weight)
        f.textColor = color
        f.alignment = .center
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }

    private func divider(theme: EmberTheme) -> NSView {
        let v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.wantsLayer = true
        v.layer?.backgroundColor = theme.border.cgColor
        return v
    }

    private func linkButton(_ title: String, url: String, theme: EmberTheme) -> NSButton {
        let btn = NSButton(title: title, target: self, action: #selector(openLink(_:)))
        btn.isBordered        = false
        btn.font              = NSFont.systemFont(ofSize: 11, weight: .regular)
        btn.contentTintColor  = theme.accent
        btn.identifier        = NSUserInterfaceItemIdentifier(url)
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
        alert.messageText     = "Developer Access"
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
                ok.messageText    = "Unlocked"
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
        if count >= 5 { count = 0; onFiveTaps?() }
    }
}
