import AppKit

class WarningBannerController: NSObject {
    var onSkip:  (() -> Void)?
    var onDelay: ((TimeInterval) -> Void)?

    private var panel: NSPanel?
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

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let w: CGFloat = 380, h: CGFloat = 96
        let origin = CGPoint(x: screen.frame.midX - w / 2,
                             y: screen.frame.maxY - h - 56)

        let p = NSPanel(
            contentRect: CGRect(origin: origin, size: CGSize(width: w, height: h)),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        p.level              = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
        p.backgroundColor    = NSColor(calibratedRed: 0.14, green: 0.18, blue: 0.28, alpha: 0.98)
        p.isOpaque           = false
        p.alphaValue         = 0
        p.hasShadow          = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        if let cv = p.contentView {
            cv.wantsLayer = true
            cv.layer?.cornerRadius  = 14
            cv.layer?.masksToBounds = true
            addContent(to: cv)
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

    private func addContent(to view: NSView) {
        let eye = NSImageView()
        eye.translatesAutoresizingMaskIntoConstraints = false
        let cfg = NSImage.SymbolConfiguration(pointSize: 20, weight: .ultraLight)
        eye.image = NSImage(systemSymbolName: "eye", accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg)
        eye.contentTintColor = NSColor(calibratedRed: 0.45, green: 0.72, blue: 1.0, alpha: 0.75)
        view.addSubview(eye)

        let lbl = NSTextField(labelWithString: "Eye break in 1 minute")
        lbl.font      = NSFont.systemFont(ofSize: 14, weight: .regular)
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lbl)

        let skipBtn  = pill("Skip this break", #selector(skipTapped))
        let delayBtn = pill("+5 min",          #selector(delayTapped))
        let dimBtn   = pill("Dismiss",         #selector(dimTapped))
        view.addSubview(skipBtn)
        view.addSubview(delayBtn)
        view.addSubview(dimBtn)

        NSLayoutConstraint.activate([
            eye.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            eye.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),

            lbl.leadingAnchor.constraint(equalTo: eye.trailingAnchor, constant: 10),
            lbl.centerYAnchor.constraint(equalTo: eye.centerYAnchor),

            skipBtn.leadingAnchor.constraint(equalTo: eye.leadingAnchor),
            skipBtn.topAnchor.constraint(equalTo: eye.bottomAnchor, constant: 10),

            delayBtn.leadingAnchor.constraint(equalTo: skipBtn.trailingAnchor, constant: 8),
            delayBtn.centerYAnchor.constraint(equalTo: skipBtn.centerYAnchor),

            dimBtn.leadingAnchor.constraint(equalTo: delayBtn.trailingAnchor, constant: 8),
            dimBtn.centerYAnchor.constraint(equalTo: skipBtn.centerYAnchor),
        ])
    }

    private func pill(_ title: String, _ action: Selector) -> NSButton {
        let b = NSButton(title: title, target: self, action: action)
        b.isBordered      = false
        b.font            = NSFont.systemFont(ofSize: 12, weight: .medium)
        b.contentTintColor = NSColor(calibratedRed: 0.50, green: 0.78, blue: 1.0, alpha: 1.0)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    @objc private func skipTapped()  { dismiss(); onSkip?() }
    @objc private func delayTapped() { dismiss(); onDelay?(5 * 60) }
    @objc private func dimTapped()   { dismiss() }
}
