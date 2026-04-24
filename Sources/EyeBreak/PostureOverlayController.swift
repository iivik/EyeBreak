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
                cv.layer?.backgroundColor = NSColor.clear.cgColor
                addContent(to: cv, screen: screen)
            }
            p.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.18
                p.animator().alphaValue = 1
            }
            panels.append(p)
        }

        AudioPlayer.playPostureAlert()

        // Total on-screen: 2.2 s — quick in, snappy rise, quick out
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            self?.dismiss()
        }
    }

    private func makePanel(for screen: NSScreen) -> NSPanel {
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
        let theme   = EmberTheme.dark
        let W       = screen.frame.width
        let H       = screen.frame.height

        // Arrow dimensions
        let AW: CGFloat = 88    // arrow total width
        let AH: CGFloat = 116   // arrow total height
        let stemW = AW * 0.30   // stem width
        let stemH = AH * 0.46   // stem height (bottom portion)
        let startY: CGFloat = H * 0.30   // 30% from bottom — lower third
        let endY:   CGFloat = H * 0.78   // 78% — near top / camera

        // ── Custom drawn arrow (CAShapeLayer — chunky, bold, designed)
        let arrowLayer = CAShapeLayer()
        let path = CGMutablePath()
        // Build upward-pointing arrow: stem at bottom, arrowhead on top
        // Coordinates in local space: (0,0) = bottom-left of arrow bounding box
        let sx = (AW - stemW) / 2          // stem left x
        let ex = (AW + stemW) / 2          // stem right x
        path.move(to:    CGPoint(x: sx,  y: 0))       // stem bottom-left
        path.addLine(to: CGPoint(x: sx,  y: stemH))   // stem top-left
        path.addLine(to: CGPoint(x: 0,   y: stemH))   // arrowhead left corner
        path.addLine(to: CGPoint(x: AW/2, y: AH))     // arrowhead tip
        path.addLine(to: CGPoint(x: AW,  y: stemH))   // arrowhead right corner
        path.addLine(to: CGPoint(x: ex,  y: stemH))   // stem top-right
        path.addLine(to: CGPoint(x: ex,  y: 0))       // stem bottom-right
        path.closeSubpath()
        arrowLayer.path      = path
        arrowLayer.fillColor = theme.accent.cgColor
        // Position: centre horizontally, start at startY
        arrowLayer.frame     = CGRect(x: W/2 - AW/2, y: startY, width: AW, height: AH)
        arrowLayer.opacity   = 0

        // Amber glow behind arrow
        let glowLayer = CALayer()
        glowLayer.frame         = CGRect(x: W/2 - 70, y: startY + AH/2 - 70, width: 140, height: 140)
        glowLayer.cornerRadius  = 70
        glowLayer.backgroundColor = theme.accent.withAlphaComponent(0.18).cgColor
        glowLayer.compositingFilter = "softLightBlendMode"
        glowLayer.opacity       = 0
        view.layer?.addSublayer(glowLayer)
        view.layer?.addSublayer(arrowLayer)

        // ── "Sit Up Straight" — amber, bold, large
        let titleView = NSTextField(labelWithString: "Sit Up Straight")
        titleView.font      = NSFont.systemFont(ofSize: 24, weight: .bold)
        titleView.textColor = theme.accent
        titleView.alignment = .center
        titleView.wantsLayer = true
        titleView.layer?.shadowColor   = NSColor.black.cgColor
        titleView.layer?.shadowOpacity = 0.85
        titleView.layer?.shadowRadius  = 8
        titleView.layer?.shadowOffset  = CGSize(width: 0, height: -2)
        titleView.frame     = CGRect(x: W/2 - 240, y: H * 0.23, width: 480, height: 32)
        titleView.alphaValue = 0
        view.addSubview(titleView)

        // ── Sub-text — warm cream, light
        let subView = NSTextField(labelWithString: "Roll shoulders back  ·  lift your chin")
        subView.font      = NSFont.systemFont(ofSize: 13, weight: .regular)
        subView.textColor = theme.textMuted
        subView.alignment = .center
        subView.wantsLayer = true
        subView.layer?.shadowColor   = NSColor.black.cgColor
        subView.layer?.shadowOpacity = 0.80
        subView.layer?.shadowRadius  = 5
        subView.frame     = CGRect(x: W/2 - 260, y: H * 0.19, width: 520, height: 22)
        subView.alphaValue = 0
        view.addSubview(subView)

        // ── Phase 1: Fade in (0 → 0.25s)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            titleView.animator().alphaValue = 1.0
            subView.animator().alphaValue   = 0.85
        }

        let fadeInAnim           = CABasicAnimation(keyPath: "opacity")
        fadeInAnim.fromValue     = 0
        fadeInAnim.toValue       = 1
        fadeInAnim.duration      = 0.22
        fadeInAnim.fillMode      = .forwards
        fadeInAnim.isRemovedOnCompletion = false
        arrowLayer.opacity       = 1
        arrowLayer.add(fadeInAnim, forKey: "fadeIn")
        glowLayer.opacity        = 1
        glowLayer.add(fadeInAnim.copy() as! CABasicAnimation, forKey: "fadeIn")

        // ── Phase 2: Arrow + glow rise (starts 0.1s, duration 1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            let riseAnim           = CABasicAnimation(keyPath: "position.y")
            // CALayer position is the CENTER of the layer
            riseAnim.fromValue     = startY + AH / 2
            riseAnim.toValue       = endY   + AH / 2
            riseAnim.duration      = 1.55
            // Fast acceleration out, smooth ease into top
            riseAnim.timingFunction = CAMediaTimingFunction(controlPoints: 0.20, 0.0, 0.2, 1.0)
            riseAnim.fillMode      = .forwards
            riseAnim.isRemovedOnCompletion = false
            arrowLayer.position    = CGPoint(x: W/2, y: endY + AH / 2)
            arrowLayer.add(riseAnim, forKey: "rise")

            // Glow follows arrow
            let glowRise           = riseAnim.copy() as! CABasicAnimation
            glowRise.fromValue     = startY + AH/2
            glowRise.toValue       = endY   + AH/2
            self.glowLayer(glowLayer, followRise: endY + AH/2, W: W)
            glowLayer.add(glowRise, forKey: "rise")
        }
    }

    private func glowLayer(_ layer: CALayer, followRise endCY: CGFloat, W: CGFloat) {
        layer.position = CGPoint(x: W/2, y: endCY)
    }

    // MARK: - Dismiss

    private func dismiss() {
        guard !panels.isEmpty else { return }
        let toClose = panels
        panels.removeAll()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            toClose.forEach { $0.animator().alphaValue = 0 }
        } completionHandler: {
            toClose.forEach { $0.orderOut(nil) }
            self.onComplete?()
        }
    }
}
