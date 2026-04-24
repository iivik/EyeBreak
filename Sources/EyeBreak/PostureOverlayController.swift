import AppKit

class PostureOverlayController {
    private var panel: NSPanel?
    private var onComplete: (() -> Void)?

    func show(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        DispatchQueue.main.async { self.build() }
    }

    // MARK: - Build

    private func build() {
        panel?.orderOut(nil)

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let w: CGFloat = 280, h: CGFloat = 200
        let origin = CGPoint(x: screen.frame.midX - w / 2,
                             y: screen.frame.midY - h / 2)

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
        p.hasShadow          = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        if let cv = p.contentView {
            cv.wantsLayer = true
            addContent(to: cv)
        }

        p.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            p.animator().alphaValue = 1
        }
        self.panel = p

        // Sharp single tap — "sit up" attitude
        NSSound(named: "Tink")?.play()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            self?.dismiss()
        }
    }

    // MARK: - Content

    private func addContent(to view: NSView) {
        // Arrow — large, floating, no box
        let arrow = NSImageView()
        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.wantsLayer = true
        let cfg = NSImage.SymbolConfiguration(pointSize: 72, weight: .ultraLight)
        arrow.image = NSImage(systemSymbolName: "arrow.up",
                              accessibilityDescription: nil)?.withSymbolConfiguration(cfg)
        arrow.contentTintColor = NSColor(calibratedRed: 0.45, green: 0.72, blue: 1.0, alpha: 0.95)
        applyShadow(to: arrow)
        view.addSubview(arrow)

        let title = floatingLabel("Sit Up Straight", size: 18, weight: .regular)
        let sub   = floatingLabel("Roll shoulders back · lift your chin", size: 12, weight: .light)
        sub.alphaValue = 0.70
        view.addSubview(title)
        view.addSubview(sub)

        NSLayoutConstraint.activate([
            arrow.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            arrow.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),

            title.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            title.topAnchor.constraint(equalTo: arrow.bottomAnchor, constant: 14),

            sub.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sub.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
        ])

        // Snap up × 3 — quick, assertive
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let anim = CAKeyframeAnimation(keyPath: "transform.translation.y")
            anim.values      = [0, -52, 0, -52, 0, -52, 0]
            anim.keyTimes    = [0, 0.12, 0.24, 0.36, 0.48, 0.60, 0.72]
            anim.timingFunctions = [
                CAMediaTimingFunction(name: .easeIn),
                CAMediaTimingFunction(name: .easeOut),
                CAMediaTimingFunction(name: .easeIn),
                CAMediaTimingFunction(name: .easeOut),
                CAMediaTimingFunction(name: .easeIn),
                CAMediaTimingFunction(name: .easeOut),
            ]
            anim.duration    = 1.6
            anim.repeatCount = 1
            arrow.layer?.add(anim, forKey: "snap")
        }
    }

    // MARK: - Helpers

    private func floatingLabel(_ text: String, size: CGFloat, weight: NSFont.Weight) -> NSTextField {
        let f = NSTextField(labelWithString: text)
        f.font      = NSFont.systemFont(ofSize: size, weight: weight)
        f.textColor = .white
        f.alignment = .center
        f.translatesAutoresizingMaskIntoConstraints = false
        f.wantsLayer = true
        // Drop shadow so text is readable on any background
        f.layer?.shadowColor   = NSColor.black.cgColor
        f.layer?.shadowOpacity = 0.85
        f.layer?.shadowRadius  = 4
        f.layer?.shadowOffset  = CGSize(width: 0, height: -1)
        return f
    }

    private func applyShadow(to view: NSView) {
        view.layer?.shadowColor   = NSColor.black.cgColor
        view.layer?.shadowOpacity = 0.6
        view.layer?.shadowRadius  = 8
        view.layer?.shadowOffset  = CGSize(width: 0, height: -2)
    }

    // MARK: - Dismiss

    private func dismiss() {
        guard let p = panel else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            p.animator().alphaValue = 0
        } completionHandler: {
            p.orderOut(nil)
            self.panel = nil
            self.onComplete?()
        }
    }
}
