import AppKit

class WarningBannerController: NSObject {
    var onSkip:  (() -> Void)?
    var onDelay: ((TimeInterval) -> Void)?

    private var panel:       NSPanel?
    private var dismissItem: DispatchWorkItem?

    func show() {
        DispatchQueue.main.async { self.build() }
    }

    func dismiss() {
        dismissItem?.cancel()
        guard let p = panel else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            p.animator().alphaValue = 0
        } completionHandler: {
            p.orderOut(nil)
            self.panel = nil
        }
    }

    // MARK: - Build

    private func build() {
        panel?.orderOut(nil)

        let theme  = EmberTheme.dark
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let w: CGFloat = 380, h: CGFloat = 90
        let origin = CGPoint(x: screen.frame.midX - w / 2,
                             y: screen.frame.maxY - h - 52)

        let p = NSPanel(
            contentRect: CGRect(origin: origin, size: CGSize(width: w, height: h)),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        p.level              = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
        p.backgroundColor    = .clear
        p.isOpaque           = false
        p.alphaValue         = 0
        p.hasShadow          = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        if let cv = p.contentView {
            cv.wantsLayer = true

            // Ember-dark background layer
            let bg = CALayer()
            bg.frame           = CGRect(x: 0, y: 0, width: w, height: h)
            bg.backgroundColor = theme.bgElev.cgColor
            bg.cornerRadius    = 14
            bg.borderColor     = theme.borderStrong.cgColor
            bg.borderWidth     = 0.5
            bg.shadowColor     = NSColor.black.cgColor
            bg.shadowOpacity   = 0.55
            bg.shadowRadius    = 18
            bg.shadowOffset    = CGSize(width: 0, height: -6)
            cv.layer?.addSublayer(bg)

            addContent(to: cv, theme: theme)
        }

        p.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            p.animator().alphaValue = 1
        }
        self.panel = p

        let wi = DispatchWorkItem { [weak self] in self?.dismiss() }
        dismissItem = wi
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: wi)
    }

    // MARK: - Content

    private func addContent(to view: NSView, theme: EmberTheme) {
        // Eye glyph
        let eye = EyeGlyphView(glyphSize: 18, color: theme.accent)
        eye.translatesAutoresizingMaskIntoConstraints = false

        // Title
        let title = NSTextField(labelWithString: "Eye break in 1 minute")
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font      = NSFont.systemFont(ofSize: 13, weight: .medium)
        title.textColor = theme.text

        // Amber accent bar (left edge)
        let accentBar = NSView()
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        accentBar.wantsLayer = true
        accentBar.layer?.backgroundColor = theme.accent.cgColor
        accentBar.layer?.cornerRadius    = 1.5

        // Buttons
        let skipBtn  = actionButton("Skip this break", theme: theme, selector: #selector(skipTapped))
        let delayBtn = actionButton("+5 min",          theme: theme, selector: #selector(delayTapped))
        let dimBtn   = actionButton("Dismiss",         theme: theme, selector: #selector(dimTapped))

        view.addSubview(accentBar)
        view.addSubview(eye)
        view.addSubview(title)
        view.addSubview(skipBtn)
        view.addSubview(delayBtn)
        view.addSubview(dimBtn)

        NSLayoutConstraint.activate([
            // Accent bar
            accentBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            accentBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),
            accentBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -18),
            accentBar.widthAnchor.constraint(equalToConstant: 3),

            // Eye
            eye.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 12),
            eye.topAnchor.constraint(equalTo: accentBar.topAnchor, constant: 1),
            eye.widthAnchor.constraint(equalToConstant: 18),
            eye.heightAnchor.constraint(equalToConstant: 18),

            // Title
            title.leadingAnchor.constraint(equalTo: eye.trailingAnchor, constant: 9),
            title.centerYAnchor.constraint(equalTo: eye.centerYAnchor),

            // Buttons row
            skipBtn.leadingAnchor.constraint(equalTo: eye.leadingAnchor),
            skipBtn.bottomAnchor.constraint(equalTo: accentBar.bottomAnchor),

            delayBtn.leadingAnchor.constraint(equalTo: skipBtn.trailingAnchor, constant: 4),
            delayBtn.centerYAnchor.constraint(equalTo: skipBtn.centerYAnchor),

            dimBtn.leadingAnchor.constraint(equalTo: delayBtn.trailingAnchor, constant: 4),
            dimBtn.centerYAnchor.constraint(equalTo: skipBtn.centerYAnchor),
        ])
    }

    private func actionButton(_ title: String, theme: EmberTheme, selector: Selector) -> NSButton {
        let b = NSButton(title: title, target: self, action: selector)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isBordered        = false
        b.font              = NSFont.systemFont(ofSize: 11, weight: .medium)
        b.contentTintColor  = theme.accent
        return b
    }

    @objc private func skipTapped()  { dismiss(); onSkip?() }
    @objc private func delayTapped() { dismiss(); onDelay?(5 * 60) }
    @objc private func dimTapped()   { dismiss() }
}
