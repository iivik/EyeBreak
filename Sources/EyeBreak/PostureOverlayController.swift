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
        let w: CGFloat = 360, h: CGFloat = 100
        let origin = CGPoint(x: screen.frame.midX - w / 2,
                             y: screen.frame.maxY - h - 56)

        let p = NSPanel(
            contentRect: CGRect(origin: origin, size: CGSize(width: w, height: h)),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        p.level              = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
        p.backgroundColor    = NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.16, alpha: 0.96)
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

        NSSound(named: "Glass")?.play()

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            self?.dismiss()
        }
    }

    // MARK: - Content

    private func addContent(to view: NSView) {
        let arrow = NSImageView()
        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.wantsLayer = true
        let cfg = NSImage.SymbolConfiguration(pointSize: 30, weight: .ultraLight)
        arrow.image = NSImage(systemSymbolName: "arrow.up.circle",
                              accessibilityDescription: nil)?.withSymbolConfiguration(cfg)
        arrow.contentTintColor = NSColor(calibratedRed: 0.45, green: 0.72, blue: 1.0, alpha: 0.9)
        view.addSubview(arrow)

        let title = field("Sit Up Straight", size: 15, weight: .light, alpha: 1.0)
        view.addSubview(title)

        let sub = field("Roll shoulders back  ·  lift your chin", size: 11, weight: .ultraLight, alpha: 0.50)
        view.addSubview(sub)

        NSLayoutConstraint.activate([
            arrow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            arrow.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 36),

            title.leadingAnchor.constraint(equalTo: arrow.trailingAnchor, constant: 14),
            title.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            sub.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            sub.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 5),
            sub.trailingAnchor.constraint(equalTo: title.trailingAnchor),
        ])

        // Bobbing arrow animation after the panel fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let anim = CAKeyframeAnimation(keyPath: "transform.translation.y")
            anim.values      = [0, -10, 0, -6, 0, -3, 0]
            anim.keyTimes    = [0, 0.2, 0.4, 0.6, 0.75, 0.88, 1.0]
            anim.duration    = 2.0
            anim.repeatCount = 2
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            arrow.layer?.add(anim, forKey: "bob")
        }
    }

    private func field(_ text: String, size: CGFloat, weight: NSFont.Weight, alpha: CGFloat) -> NSTextField {
        let f = NSTextField(labelWithString: text)
        f.font      = NSFont.systemFont(ofSize: size, weight: weight)
        f.textColor = NSColor.white.withAlphaComponent(alpha)
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }

    // MARK: - Dismiss

    private func dismiss() {
        guard let p = panel else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.4
            p.animator().alphaValue = 0
        } completionHandler: {
            p.orderOut(nil)
            self.panel = nil
            self.onComplete?()
        }
    }
}
