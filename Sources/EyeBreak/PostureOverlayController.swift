import AppKit

class PostureOverlayController {
    private var panels:     [NSPanel] = []
    private var onComplete: (() -> Void)?

    func show(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        DispatchQueue.main.async { self.build() }
    }

    // MARK: - Build

    private func build() {
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()

        for screen in NSScreen.screens {
            let p = makePanel(for: screen)
            if let cv = p.contentView {
                cv.wantsLayer = true
                addContent(to: cv, screen: screen)
            }
            p.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.20
                p.animator().alphaValue = 1
            }
            panels.append(p)
        }

        // Sharp marimba-style double-ping — distinct from break sounds
        AudioPlayer.playPostureAlert()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            self?.dismiss()
        }
    }

    private func makePanel(for screen: NSScreen) -> NSPanel {
        // Full-screen transparent panel so the arrow can float at any position
        let p = NSPanel(
            contentRect: screen.frame,
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        p.level              = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 2)
        p.backgroundColor    = .clear
        p.isOpaque           = false
        p.alphaValue         = 0
        p.hasShadow          = false
        p.ignoresMouseEvents = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        return p
    }

    // MARK: - Content

    private func addContent(to view: NSView, screen: NSScreen) {
        let theme    = EmberTheme.dark
        let arrowColor = theme.accent          // amber — visible on any background

        // ── Arrow — large, free-floating, pointing up toward the camera
        let arrow = NSImageView()
        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.wantsLayer = true
        let cfg = NSImage.SymbolConfiguration(pointSize: 110, weight: .ultraLight)
        arrow.image = NSImage(systemSymbolName: "arrow.up",
                              accessibilityDescription: nil)?.withSymbolConfiguration(cfg)
        arrow.contentTintColor = arrowColor
        applyShadow(to: arrow, color: NSColor.black, opacity: 0.70, radius: 12)
        view.addSubview(arrow)

        // ── "Sit Up Straight" — bold enough to be read anywhere
        let title = floatingLabel("Sit Up Straight",
                                   size: 20, weight: .medium,
                                   color: .white)
        applyShadow(to: title, color: NSColor.black, opacity: 0.85, radius: 5)
        view.addSubview(title)

        // ── Sub label
        let sub = floatingLabel("Roll shoulders back  ·  lift your chin",
                                 size: 13, weight: .light,
                                 color: NSColor.white.withAlphaComponent(0.75))
        applyShadow(to: sub, color: NSColor.black, opacity: 0.85, radius: 4)
        view.addSubview(sub)

        // ── Amber glow under arrow
        let glow = NSView()
        glow.translatesAutoresizingMaskIntoConstraints = false
        glow.wantsLayer = true
        let glowLayer = CAGradientLayer()
        glowLayer.type   = .radial
        glowLayer.colors = [arrowColor.withAlphaComponent(0.25).cgColor, NSColor.clear.cgColor]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint   = CGPoint(x: 1.0, y: 1.0)
        glow.layer?.addSublayer(glowLayer)
        view.addSubview(glow)

        // Place everything centred, arrow in upper-centre zone
        // (biased toward top 40% of screen so it points clearly toward camera)
        let midX = screen.frame.width  / 2
        let midY = screen.frame.height * 0.58   // sit in upper-center

        NSLayoutConstraint.activate([
            arrow.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: midX),
            arrow.centerYAnchor.constraint(equalTo: view.bottomAnchor,  constant: midY),

            title.centerXAnchor.constraint(equalTo: arrow.centerXAnchor),
            title.topAnchor.constraint(equalTo: arrow.bottomAnchor, constant: 12),

            sub.centerXAnchor.constraint(equalTo: arrow.centerXAnchor),
            sub.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),

            glow.centerXAnchor.constraint(equalTo: arrow.centerXAnchor),
            glow.centerYAnchor.constraint(equalTo: arrow.centerYAnchor),
            glow.widthAnchor.constraint(equalToConstant: 200),
            glow.heightAnchor.constraint(equalToConstant: 200),
        ])

        // Lay out glow gradient frame after layout pass
        DispatchQueue.main.async {
            glowLayer.frame = glow.bounds
        }

        // ── Bounce animation: 3 quick assertive snaps upward
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let anim         = CAKeyframeAnimation(keyPath: "transform.translation.y")
            anim.values      = [0, -46, 0, -46, 0, -46, 0]
            anim.keyTimes    = [0, 0.10, 0.22, 0.32, 0.44, 0.54, 0.66]
            anim.timingFunctions = (0..<6).map { i in
                CAMediaTimingFunction(name: i % 2 == 0 ? .easeIn : .easeOut)
            }
            anim.duration    = 1.5
            anim.repeatCount = 1
            arrow.layer?.add(anim, forKey: "snap")
        }
    }

    // MARK: - Helpers

    private func floatingLabel(_ text: String, size: CGFloat,
                                weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let f = NSTextField(labelWithString: text)
        f.font      = NSFont.systemFont(ofSize: size, weight: weight)
        f.textColor = color
        f.alignment = .center
        f.translatesAutoresizingMaskIntoConstraints = false
        f.wantsLayer = true
        return f
    }

    private func applyShadow(to view: NSView, color: NSColor,
                              opacity: Float, radius: CGFloat) {
        view.layer?.shadowColor   = color.cgColor
        view.layer?.shadowOpacity = opacity
        view.layer?.shadowRadius  = radius
        view.layer?.shadowOffset  = CGSize(width: 0, height: -2)
    }

    // MARK: - Dismiss

    private func dismiss() {
        guard !panels.isEmpty else { return }
        let toClose = panels
        panels.removeAll()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.30
            toClose.forEach { $0.animator().alphaValue = 0 }
        } completionHandler: {
            toClose.forEach { $0.orderOut(nil) }
            self.onComplete?()
        }
    }
}
