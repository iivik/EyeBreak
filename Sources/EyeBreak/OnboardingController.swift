import AppKit

/// Shows exactly once on first launch. Tooltip anchored to top-right of screen
/// (where the menu bar status icons live), pointing up at the eye icon.
class OnboardingController {

    private static let seenKey = "com.eyebreak.onboardingSeen"
    // Static reference keeps the controller alive until explicitly dismissed
    private static var live: OnboardingController?

    private var panel: NSPanel?

    // MARK: - Public

    static func showIfNeeded(after delay: TimeInterval = 1.2) {
        guard !UserDefaults.standard.bool(forKey: seenKey) else { return }
        let ctrl = OnboardingController()
        live = ctrl
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            ctrl.show()
        }
    }

    // MARK: - Build

    private func show() {
        UserDefaults.standard.set(true, forKey: Self.seenKey)

        let theme       = EmberTheme.dark
        let w: CGFloat  = 292
        let cardH: CGFloat = 100
        let tipH: CGFloat  = 10
        let h           = cardH + tipH

        guard let screen = NSScreen.main else { return }

        // Top-right corner — status item icons cluster here
        let menuBarH = NSStatusBar.system.thickness
        let x = screen.frame.maxX - w - 16
        let y = screen.frame.maxY - menuBarH - h - 6

        let p = NSPanel(
            contentRect: CGRect(x: x, y: y, width: w, height: h),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        p.level              = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
        p.backgroundColor    = .clear
        p.isOpaque           = false
        p.alphaValue         = 0
        p.hasShadow          = false
        p.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.panel = p

        if let cv = p.contentView {
            cv.wantsLayer = true
            cv.layer?.backgroundColor = NSColor.clear.cgColor
            buildContent(in: cv, theme: theme, w: w, cardH: cardH, tipH: tipH)
        }

        p.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            p.animator().alphaValue = 1
        }

        // Auto-dismiss after 9 s
        DispatchQueue.main.asyncAfter(deadline: .now() + 9) { [weak self] in
            self?.dismiss()
        }
    }

    // MARK: - Content

    private func buildContent(in view: NSView, theme: EmberTheme,
                               w: CGFloat, cardH: CGFloat, tipH: CGFloat) {
        // ── Card background
        let card = CALayer()
        card.frame           = CGRect(x: 0, y: 0, width: w, height: cardH)
        card.backgroundColor = theme.bgElev.cgColor
        card.cornerRadius    = 12
        card.borderColor     = theme.borderStrong.cgColor
        card.borderWidth     = 0.5
        card.shadowColor     = NSColor.black.cgColor
        card.shadowOpacity   = 0.60
        card.shadowRadius    = 18
        card.shadowOffset    = CGSize(width: 0, height: -5)
        view.layer?.addSublayer(card)

        // ── Upward tip triangle (points at menu bar from below)
        let tip      = CAShapeLayer()
        let tipPath  = CGMutablePath()
        // Tip is in the top-right area of the card (roughly where the icon sits)
        let tipMidX  = w - 60.0
        tipPath.move(to: CGPoint(x: tipMidX,      y: cardH + tipH)) // apex
        tipPath.addLine(to: CGPoint(x: tipMidX - 9, y: cardH))
        tipPath.addLine(to: CGPoint(x: tipMidX + 9, y: cardH))
        tipPath.closeSubpath()
        tip.path      = tipPath
        tip.fillColor = theme.bgElev.cgColor
        view.layer?.addSublayer(tip)

        // ── Amber dot (pulsing)
        let dot = CALayer()
        dot.frame           = CGRect(x: 18, y: cardH - 26, width: 7, height: 7)
        dot.cornerRadius    = 3.5
        dot.backgroundColor = theme.accent.cgColor
        dot.shadowColor     = theme.accent.cgColor
        dot.shadowOpacity   = 0.85
        dot.shadowRadius    = 4
        dot.shadowOffset    = .zero
        view.layer?.addSublayer(dot)

        let pulse           = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue     = 1.0
        pulse.toValue       = 0.25
        pulse.duration      = 0.85
        pulse.autoreverses  = true
        pulse.repeatCount   = .infinity
        dot.add(pulse, forKey: "pulse")

        // ── Headline
        let headline = makeLabel("Your 20-20-20 timer is running",
                                  size: 13, weight: .semibold, color: theme.text)
        headline.frame = CGRect(x: 33, y: cardH - 28, width: w - 50, height: 20)
        view.addSubview(headline)

        // ── Body
        let body = makeLabel("Every 20 min · look 20 ft away · for 20 sec",
                              size: 11, weight: .regular, color: theme.textMuted)
        body.frame = CGRect(x: 18, y: cardH - 52, width: w - 36, height: 18)
        view.addSubview(body)

        // ── Hint
        let hint = makeLabel("Click the eye icon anytime to change settings",
                              size: 10, weight: .regular, color: theme.textDim)
        hint.frame = CGRect(x: 18, y: cardH - 70, width: w - 36, height: 16)
        view.addSubview(hint)

        // ── Got it button
        let btn = NSButton(title: "Got it  →", target: self, action: #selector(dismissTapped))
        btn.isBordered       = false
        btn.font             = NSFont.systemFont(ofSize: 11, weight: .semibold)
        btn.contentTintColor = theme.accent
        btn.frame = CGRect(x: w - 72, y: 12, width: 60, height: 18)
        view.addSubview(btn)
    }

    // MARK: - Helpers

    private func makeLabel(_ text: String, size: CGFloat,
                            weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let f = NSTextField(labelWithString: text)
        f.font      = NSFont.systemFont(ofSize: size, weight: weight)
        f.textColor = color
        f.alignment = .left
        return f
    }

    @objc private func dismissTapped() { dismiss() }

    private func dismiss() {
        guard let p = panel else { return }
        panel = nil
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            p.animator().alphaValue = 0
        } completionHandler: {
            p.orderOut(nil)
            OnboardingController.live = nil   // release self
        }
    }
}
