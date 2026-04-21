import AppKit

private class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool  { true }
    override var canBecomeMain: Bool { true }
}

class OverlayWindowController {
    private var windows: [OverlayWindow] = []
    private var countdownLabel: NSTextField?
    private var ticker: Timer?
    private var secondsLeft = 20
    private var onComplete: (() -> Void)?

    // MARK: - Public

    func show(onComplete: @escaping () -> Void) {
        self.onComplete  = onComplete
        self.secondsLeft = 20
        DispatchQueue.main.async {
            self.buildOverlays()
            self.startCountdown()
        }
    }

    // MARK: - Overlay Construction

    private func buildOverlays() {
        tearDown()
        for (index, screen) in NSScreen.screens.enumerated() {
            let window = makeWindow(for: screen)
            addContent(to: window, screen: screen, isPrimary: index == 0)
            window.orderFrontRegardless()
            windows.append(window)
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.6
            windows.forEach { $0.animator().alphaValue = 1 }
        }
    }

    private func makeWindow(for screen: NSScreen) -> OverlayWindow {
        let win = OverlayWindow(
            contentRect: screen.frame,
            styleMask:   .borderless,
            backing:     .buffered,
            defer:       false,
            screen:      screen
        )
        win.level            = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        win.backgroundColor  = NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.10, alpha: 0.96)
        win.isOpaque         = false
        win.alphaValue       = 0
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        win.setFrame(screen.frame, display: false)
        return win
    }

    // MARK: - Content

    private func addContent(to window: OverlayWindow, screen: NSScreen, isPrimary: Bool) {
        guard let view = window.contentView else { return }
        view.wantsLayer = true

        let scale: CGFloat = isPrimary ? 1.0 : 0.72

        // ── Eye icon (SF Symbol)
        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        let symCfg = NSImage.SymbolConfiguration(pointSize: 48 * scale, weight: .ultraLight)
        if let img = NSImage(systemSymbolName: "eye", accessibilityDescription: nil) {
            iconView.image = img.withSymbolConfiguration(symCfg)
        }
        iconView.contentTintColor = NSColor(calibratedRed: 0.45, green: 0.72, blue: 1.0, alpha: 0.75)
        view.addSubview(iconView)

        // ── Primary message
        let mainLabel  = label("Look Away", size: 80 * scale, weight: .thin, color: .white)
        let ruleLabel  = label("20 feet  ·  20 seconds  ·  every 20 minutes",
                                size: 18 * scale, weight: .ultraLight,
                                color: NSColor.white.withAlphaComponent(0.50))
        view.addSubview(mainLabel)
        view.addSubview(ruleLabel)

        var constraints: [NSLayoutConstraint] = [
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -110 * scale),

            mainLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 16 * scale),

            ruleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ruleLabel.topAnchor.constraint(equalTo: mainLabel.bottomAnchor, constant: 10 * scale),
        ]

        if isPrimary {
            // ── Countdown ring area
            let countdown = NSTextField(labelWithString: "20")
            countdown.font      = NSFont.monospacedDigitSystemFont(ofSize: 58, weight: .ultraLight)
            countdown.textColor = NSColor.white.withAlphaComponent(0.38)
            countdown.alignment = .center
            countdown.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(countdown)
            self.countdownLabel = countdown

            let secondsHint = label("seconds", size: 13, weight: .light,
                                    color: NSColor.white.withAlphaComponent(0.28))
            view.addSubview(secondsHint)

            constraints += [
                countdown.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                countdown.topAnchor.constraint(equalTo: ruleLabel.bottomAnchor, constant: 38),
                secondsHint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                secondsHint.topAnchor.constraint(equalTo: countdown.bottomAnchor, constant: 4),
            ]

            // ── Trial expired banner (shown only when trial is up and not purchased)
            if TrialManager.shared.isTrialExpired {
                addTrialExpiredBanner(to: view, constraints: &constraints)
            }
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func addTrialExpiredBanner(to view: NSView, constraints: inout [NSLayoutConstraint]) {
        // Semi-transparent pill at the bottom of the primary screen
        let pill = NSView()
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.wantsLayer = true
        pill.layer?.backgroundColor = NSColor(calibratedRed: 0.95, green: 0.35, blue: 0.30, alpha: 0.18).cgColor
        pill.layer?.cornerRadius = 12
        pill.layer?.borderColor  = NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.40, alpha: 0.35).cgColor
        pill.layer?.borderWidth  = 0.5
        view.addSubview(pill)

        let msg = label("Trial expired  ·  EyeBreak is free to use — purchase to support development.",
                        size: 12, weight: .light,
                        color: NSColor.white.withAlphaComponent(0.70))
        msg.maximumNumberOfLines = 1
        pill.addSubview(msg)

        constraints += [
            pill.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pill.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -36),
            pill.widthAnchor.constraint(lessThanOrEqualToConstant: 560),

            msg.topAnchor.constraint(equalTo: pill.topAnchor, constant: 10),
            msg.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -10),
            msg.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 20),
            msg.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -20),
        ]
    }

    // MARK: - Countdown

    private func startCountdown() {
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.secondsLeft -= 1
            self.countdownLabel?.stringValue = "\(self.secondsLeft)"
            if self.secondsLeft <= 0 { self.dismiss() }
        }
        RunLoop.main.add(ticker!, forMode: .common)
    }

    private func dismiss() {
        ticker?.invalidate()
        ticker = nil
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.5
            windows.forEach { $0.animator().alphaValue = 0 }
        } completionHandler: {
            self.tearDown()
            self.onComplete?()
        }
    }

    private func tearDown() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        countdownLabel = nil
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
}
