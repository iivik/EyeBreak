import AppKit

// MARK: - OverlayWindow

private class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool  { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - BreakContentView

private class BreakContentView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let b = bounds

        // 1. Radial gradient background
        let center   = CGPoint(x: b.midX, y: b.height * 0.55)
        let outerR   = max(b.width, b.height) * 0.9
        let bgColors = [
            NSColor(hex: "#2a1d14").cgColor,
            NSColor(hex: "#0d0806").cgColor,
            NSColor(hex: "#050302").cgColor,
        ] as CFArray
        let bgLocs: [CGFloat] = [0.0, 0.70, 1.0]
        guard let bgGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: bgColors, locations: bgLocs) else { return }
        ctx.drawRadialGradient(bgGrad,
                               startCenter: center, startRadius: 0,
                               endCenter:   center, endRadius:   outerR,
                               options:     [.drawsAfterEndLocation])

        // 2. Vignette overlay
        let vigCenter  = CGPoint(x: b.midX, y: b.midY)
        let vigInnerR  = min(b.width, b.height) * 0.30
        let vigOuterR  = max(b.width, b.height) * 0.75
        let vigColors  = [
            NSColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor,
            NSColor(red: 0, green: 0, blue: 0, alpha: 0.45).cgColor,
        ] as CFArray
        let vigLocs: [CGFloat] = [0.0, 1.0]
        guard let vigGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                       colors: vigColors, locations: vigLocs) else { return }
        ctx.drawRadialGradient(vigGrad,
                               startCenter: vigCenter, startRadius: vigInnerR,
                               endCenter:   vigCenter, endRadius:   vigOuterR,
                               options:     [.drawsAfterEndLocation])
    }
}

// MARK: - OverlayWindowController

class OverlayWindowController {
    private var windows:        [OverlayWindow] = []
    private var countdownLabel: NSTextField?
    private var timeLabel:      NSTextField?
    private var ticker:         Timer?
    private var timeTicker:     Timer?
    private var secondsLeft:    Int = 20
    private var onComplete:     (() -> Void)?
    private var keyMonitor:     Any?

    // MARK: - Public

    func show(duration: Int, onComplete: @escaping () -> Void) {
        self.onComplete  = onComplete
        self.secondsLeft = duration
        DispatchQueue.main.async {
            self.buildOverlays()
            self.startCountdown()
            self.installKeyMonitor()
        }
    }

    // MARK: - Overlay Construction

    private func buildOverlays() {
        tearDown()
        for (index, screen) in NSScreen.screens.enumerated() {
            let window = makeWindow(for: screen)
            let contentView = BreakContentView()
            contentView.wantsLayer = true
            window.contentView = contentView
            addContent(to: contentView, screen: screen, isPrimary: index == 0)
            setupRings(in: contentView, screen: screen)
            window.orderFrontRegardless()
            windows.append(window)
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.5
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
        win.level              = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        win.backgroundColor    = NSColor(hex: "#0d0806")
        win.isOpaque           = false
        win.alphaValue         = 0
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        win.setFrame(screen.frame, display: false)
        return win
    }

    // MARK: - Breathing Rings

    private func setupRings(in view: NSView, screen: NSScreen) {
        guard let rootLayer = view.layer else { return }
        let cx = screen.frame.width / 2
        let cy = screen.frame.height / 2

        // Inner ring: 340pt
        let innerRing = CALayer()
        innerRing.frame           = CGRect(x: cx - 170, y: cy - 170, width: 340, height: 340)
        innerRing.cornerRadius    = 170
        innerRing.backgroundColor = NSColor.clear.cgColor
        innerRing.borderColor     = NSColor(hex: "#f4b88a").cgColor
        innerRing.borderWidth     = 1
        innerRing.opacity         = 0.08
        rootLayer.addSublayer(innerRing)

        let innerAnim             = CABasicAnimation(keyPath: "opacity")
        innerAnim.fromValue       = 0.08
        innerAnim.toValue         = 0.22
        innerAnim.duration        = 1.8
        innerAnim.timingFunction  = CAMediaTimingFunction(name: .easeInEaseOut)
        innerAnim.autoreverses    = true
        innerAnim.repeatCount     = .infinity
        innerRing.add(innerAnim, forKey: "breathe")

        // Outer ring: 460pt
        let outerRing = CALayer()
        outerRing.frame           = CGRect(x: cx - 230, y: cy - 230, width: 460, height: 460)
        outerRing.cornerRadius    = 230
        outerRing.backgroundColor = NSColor.clear.cgColor
        outerRing.borderColor     = NSColor(hex: "#f4b88a").cgColor
        outerRing.borderWidth     = 1
        outerRing.opacity         = 0.04
        rootLayer.addSublayer(outerRing)

        let outerAnim             = CABasicAnimation(keyPath: "opacity")
        outerAnim.fromValue       = 0.04
        outerAnim.toValue         = 0.10
        outerAnim.duration        = 1.8
        outerAnim.timingFunction  = CAMediaTimingFunction(name: .easeInEaseOut)
        outerAnim.autoreverses    = true
        outerAnim.repeatCount     = .infinity
        outerRing.add(outerAnim, forKey: "breathe")
    }

    // MARK: - Content

    private func addContent(to view: NSView, screen: NSScreen, isPrimary: Bool) {
        let theme = EmberTheme.dark

        // Center stack container
        let center = NSView()
        center.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(center)

        // Eye glyph
        let eyeGlyph = EyeGlyphView(glyphSize: 52, color: theme.breakAccent)

        // Eye glow layer (behind glyph)
        let glowContainer = NSView()
        glowContainer.translatesAutoresizingMaskIntoConstraints = false
        glowContainer.wantsLayer = true
        let glowLayer = CAGradientLayer()
        glowLayer.type   = .radial
        glowLayer.colors = [theme.breakAccent.withAlphaComponent(0.22).cgColor,
                            NSColor.clear.cgColor]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint   = CGPoint(x: 1.0, y: 1.0)
        glowLayer.opacity    = 1.0
        glowContainer.layer?.addSublayer(glowLayer)
        glowContainer.layer?.masksToBounds = false

        // "Look Away" label
        let lookAway = NSTextField(labelWithString: "Look Away")
        lookAway.translatesAutoresizingMaskIntoConstraints = false
        lookAway.font      = NSFont.systemFont(ofSize: 54, weight: .thin)
        lookAway.textColor = theme.breakText
        lookAway.alignment = .center
        let lookAwayStr = NSMutableAttributedString(string: "Look Away")
        lookAwayStr.addAttribute(.kern, value: -1.9 as NSNumber, range: NSRange(location: 0, length: lookAwayStr.length))
        lookAwayStr.addAttribute(.font, value: NSFont.systemFont(ofSize: 54, weight: .thin), range: NSRange(location: 0, length: lookAwayStr.length))
        lookAwayStr.addAttribute(.foregroundColor, value: theme.breakText, range: NSRange(location: 0, length: lookAwayStr.length))
        lookAway.attributedStringValue = lookAwayStr

        // Meta row
        let metaStr = NSMutableAttributedString()
        let metaFont = NSFont.systemFont(ofSize: 12, weight: .medium)
        let metaColor = theme.breakMeta
        let dotColor  = theme.breakMeta.withAlphaComponent(0.40)
        for (i, segment) in ["20 feet", " · ", "20 seconds", " · ", "every 20 minutes"].enumerated() {
            let color = (i % 2 == 1) ? dotColor : metaColor
            metaStr.append(NSAttributedString(string: segment, attributes: [
                .font: metaFont,
                .foregroundColor: color,
            ]))
        }
        let metaLabel = NSTextField(labelWithAttributedString: metaStr)
        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        metaLabel.alignment = .center

        // Countdown stack
        let countdownContainer = NSView()
        countdownContainer.translatesAutoresizingMaskIntoConstraints = false

        let countdownNum = NSTextField(labelWithString: "\(secondsLeft)")
        countdownNum.translatesAutoresizingMaskIntoConstraints = false
        countdownNum.font      = NSFont.monospacedDigitSystemFont(ofSize: 56, weight: .ultraLight)
        countdownNum.textColor = theme.breakNumber
        countdownNum.alignment = .center
        let cNumStr = NSMutableAttributedString(string: "\(secondsLeft)")
        cNumStr.addAttribute(.kern, value: -1.7 as NSNumber, range: NSRange(location: 0, length: cNumStr.length))
        cNumStr.addAttribute(.font, value: NSFont.monospacedDigitSystemFont(ofSize: 56, weight: .ultraLight), range: NSRange(location: 0, length: cNumStr.length))
        cNumStr.addAttribute(.foregroundColor, value: theme.breakNumber, range: NSRange(location: 0, length: cNumStr.length))
        countdownNum.attributedStringValue = cNumStr

        let secondsLbl = NSTextField(labelWithString: "SECONDS")
        secondsLbl.translatesAutoresizingMaskIntoConstraints = false
        let secStr = NSMutableAttributedString(string: "SECONDS")
        secStr.addAttribute(.font, value: NSFont.systemFont(ofSize: 10, weight: .medium), range: NSRange(location: 0, length: 7))
        secStr.addAttribute(.foregroundColor, value: metaColor, range: NSRange(location: 0, length: 7))
        secStr.addAttribute(.kern, value: 2.2 as NSNumber, range: NSRange(location: 0, length: 7))
        secondsLbl.attributedStringValue = secStr
        secondsLbl.alignment = .center

        countdownContainer.addSubview(countdownNum)
        countdownContainer.addSubview(secondsLbl)

        center.addSubview(glowContainer)
        center.addSubview(eyeGlyph)
        center.addSubview(lookAway)
        center.addSubview(metaLabel)
        center.addSubview(countdownContainer)

        if isPrimary {
            self.countdownLabel = countdownNum
        }

        NSLayoutConstraint.activate([
            center.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            center.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            glowContainer.centerXAnchor.constraint(equalTo: center.leadingAnchor),
            glowContainer.centerYAnchor.constraint(equalTo: center.topAnchor),
            glowContainer.widthAnchor.constraint(equalToConstant: 80),
            glowContainer.heightAnchor.constraint(equalToConstant: 80),

            eyeGlyph.centerXAnchor.constraint(equalTo: center.centerXAnchor),
            eyeGlyph.topAnchor.constraint(equalTo: center.topAnchor),
            eyeGlyph.widthAnchor.constraint(equalToConstant: 52),
            eyeGlyph.heightAnchor.constraint(equalToConstant: 52),

            lookAway.centerXAnchor.constraint(equalTo: center.centerXAnchor),
            lookAway.topAnchor.constraint(equalTo: eyeGlyph.bottomAnchor, constant: 14),

            metaLabel.centerXAnchor.constraint(equalTo: center.centerXAnchor),
            metaLabel.topAnchor.constraint(equalTo: lookAway.bottomAnchor, constant: 14),

            countdownContainer.centerXAnchor.constraint(equalTo: center.centerXAnchor),
            countdownContainer.topAnchor.constraint(equalTo: metaLabel.bottomAnchor, constant: 22),
            countdownContainer.bottomAnchor.constraint(equalTo: center.bottomAnchor),
            countdownContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            countdownNum.topAnchor.constraint(equalTo: countdownContainer.topAnchor),
            countdownNum.centerXAnchor.constraint(equalTo: countdownContainer.centerXAnchor),

            secondsLbl.topAnchor.constraint(equalTo: countdownNum.bottomAnchor, constant: 4),
            secondsLbl.centerXAnchor.constraint(equalTo: countdownContainer.centerXAnchor),
            secondsLbl.bottomAnchor.constraint(equalTo: countdownContainer.bottomAnchor),
        ])

        // Position glow to overlap eye
        DispatchQueue.main.async {
            if let eyeFrame = eyeGlyph.superview?.convert(eyeGlyph.frame, to: view) {
                glowLayer.frame = CGRect(x: eyeFrame.midX - 40, y: eyeFrame.midY - 40, width: 80, height: 80)
            }
        }

        if isPrimary {
            addCornerElements(to: view, theme: theme)
        }
    }

    private func addCornerElements(to view: NSView, theme: EmberTheme) {
        // Top-left: dot + EYEBREAK
        let topLeft = NSView()
        topLeft.translatesAutoresizingMaskIntoConstraints = false
        topLeft.wantsLayer = true
        topLeft.alphaValue = 0.55
        view.addSubview(topLeft)

        let dotLayer = CALayer()
        dotLayer.frame           = CGRect(x: 0, y: 7, width: 6, height: 6)
        dotLayer.cornerRadius    = 3
        dotLayer.backgroundColor = theme.breakAccent.cgColor
        dotLayer.shadowColor     = theme.breakAccent.cgColor
        dotLayer.shadowOpacity   = 0.9
        dotLayer.shadowRadius    = 3
        dotLayer.shadowOffset    = .zero
        topLeft.layer?.addSublayer(dotLayer)

        let eyebreakStr = NSMutableAttributedString(string: "EYEBREAK")
        eyebreakStr.addAttribute(.font, value: NSFont.systemFont(ofSize: 10, weight: .semibold), range: NSRange(location: 0, length: 8))
        eyebreakStr.addAttribute(.foregroundColor, value: theme.breakMeta, range: NSRange(location: 0, length: 8))
        eyebreakStr.addAttribute(.kern, value: 2.2 as NSNumber, range: NSRange(location: 0, length: 8))
        let eyebreakLbl = NSTextField(labelWithAttributedString: eyebreakStr)
        eyebreakLbl.translatesAutoresizingMaskIntoConstraints = false
        topLeft.addSubview(eyebreakLbl)

        NSLayoutConstraint.activate([
            eyebreakLbl.leadingAnchor.constraint(equalTo: topLeft.leadingAnchor, constant: 14),
            eyebreakLbl.centerYAnchor.constraint(equalTo: topLeft.centerYAnchor),
            eyebreakLbl.trailingAnchor.constraint(equalTo: topLeft.trailingAnchor),

            topLeft.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topLeft.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),
            topLeft.heightAnchor.constraint(equalToConstant: 20),
        ])

        // Top-right: time
        let timeLbl = NSTextField(labelWithString: currentTimeString())
        timeLbl.translatesAutoresizingMaskIntoConstraints = false
        timeLbl.font       = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        timeLbl.textColor  = theme.breakMeta.withAlphaComponent(0.70)
        timeLbl.alignment  = .right
        view.addSubview(timeLbl)
        self.timeLabel = timeLbl

        NSLayoutConstraint.activate([
            timeLbl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            timeLbl.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),
        ])

        // Start time update timer
        timeTicker = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.timeLabel?.stringValue = self?.currentTimeString() ?? ""
        }
        RunLoop.main.add(timeTicker!, forMode: .common)

        // Bottom-center: [esc] to skip
        let escContainer = NSView()
        escContainer.translatesAutoresizingMaskIntoConstraints = false
        escContainer.alphaValue = 0.70
        view.addSubview(escContainer)

        let escPill = NSView()
        escPill.translatesAutoresizingMaskIntoConstraints = false
        escPill.wantsLayer = true
        escPill.layer?.backgroundColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.06).cgColor
        escPill.layer?.cornerRadius    = 4
        escPill.layer?.borderColor     = EmberTheme.dark.borderStrong.cgColor
        escPill.layer?.borderWidth     = 0.5
        escContainer.addSubview(escPill)

        let escLbl = NSTextField(labelWithString: "esc")
        escLbl.translatesAutoresizingMaskIntoConstraints = false
        escLbl.font      = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        escLbl.textColor = EmberTheme.dark.breakText
        escPill.addSubview(escLbl)

        let skipLbl = NSTextField(labelWithString: " to skip")
        skipLbl.translatesAutoresizingMaskIntoConstraints = false
        skipLbl.font      = NSFont.systemFont(ofSize: 10, weight: .regular)
        skipLbl.textColor = EmberTheme.dark.breakMeta
        escContainer.addSubview(skipLbl)

        NSLayoutConstraint.activate([
            escLbl.topAnchor.constraint(equalTo: escPill.topAnchor, constant: 1),
            escLbl.bottomAnchor.constraint(equalTo: escPill.bottomAnchor, constant: -1),
            escLbl.leadingAnchor.constraint(equalTo: escPill.leadingAnchor, constant: 6),
            escLbl.trailingAnchor.constraint(equalTo: escPill.trailingAnchor, constant: -6),

            escPill.leadingAnchor.constraint(equalTo: escContainer.leadingAnchor),
            escPill.centerYAnchor.constraint(equalTo: escContainer.centerYAnchor),

            skipLbl.leadingAnchor.constraint(equalTo: escPill.trailingAnchor, constant: 6),
            skipLbl.centerYAnchor.constraint(equalTo: escContainer.centerYAnchor),
            skipLbl.trailingAnchor.constraint(equalTo: escContainer.trailingAnchor),

            escContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            escContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -22),
            escContainer.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    // MARK: - Countdown

    private func startCountdown() {
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.secondsLeft -= 1
            self.updateCountdownLabel()
            if self.secondsLeft <= 0 { self.dismiss() }
        }
        RunLoop.main.add(ticker!, forMode: .common)
    }

    private func updateCountdownLabel() {
        guard let label = countdownLabel else { return }
        let theme = EmberTheme.dark
        let str   = NSMutableAttributedString(string: "\(secondsLeft)")
        str.addAttribute(.kern, value: -1.7 as NSNumber, range: NSRange(location: 0, length: str.length))
        str.addAttribute(.font, value: NSFont.monospacedDigitSystemFont(ofSize: 56, weight: .ultraLight), range: NSRange(location: 0, length: str.length))
        str.addAttribute(.foregroundColor, value: theme.breakNumber, range: NSRange(location: 0, length: str.length))
        label.attributedStringValue = str
    }

    // MARK: - Key Monitor

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.dismiss()
                return nil
            }
            return event
        }
    }

    // MARK: - Dismiss

    private func dismiss() {
        ticker?.invalidate()
        ticker = nil
        timeTicker?.invalidate()
        timeTicker = nil
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.5
            self.windows.forEach { $0.animator().alphaValue = 0 }
        } completionHandler: {
            self.tearDown()
            self.onComplete?()
        }
    }

    private func tearDown() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        countdownLabel = nil
        timeLabel      = nil
    }

    // MARK: - Helpers

    private func currentTimeString() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: Date())
    }
}
