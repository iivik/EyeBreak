import AppKit

class SettingsWindowController: NSWindowController {
    private static var instance: SettingsWindowController?

    static func show() {
        if instance == nil { instance = SettingsWindowController() }
        instance?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private var breakValueLabel: NSTextField!
    private var postureIntervalSlider: NSSlider!
    private var postureIntervalLabel: NSTextField!

    init() {
        let win = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 510),
            styleMask:   [.titled, .closable, .fullSizeContentView],
            backing:     .buffered,
            defer:       false
        )
        win.titlebarAppearsTransparent = true
        win.titleVisibility            = .hidden
        win.isMovableByWindowBackground = true
        win.center()
        win.title = "EyeBreak Settings"
        super.init(window: win)
        build()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    private func build() {
        guard let view = window?.contentView else { return }
        view.wantsLayer = true

        let grad = CAGradientLayer()
        grad.frame = view.bounds
        grad.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        grad.colors = [
            NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.16, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.02, green: 0.03, blue: 0.06, alpha: 1).cgColor,
        ]
        grad.startPoint = CGPoint(x: 0.5, y: 0)
        grad.endPoint   = CGPoint(x: 0.5, y: 1)
        view.layer?.addSublayer(grad)

        // ── Title
        let titleLbl = label("Settings", size: 18, weight: .thin, alpha: 1.0)
        view.addSubview(titleLbl)

        // ── EYE BREAK
        let eyeHdr = sectionHeader("EYE BREAK")
        view.addSubview(eyeHdr)

        let breakLbl = label("Break every", size: 13, weight: .regular, alpha: 1.0)
        view.addSubview(breakLbl)

        let breakSlider = NSSlider()
        breakSlider.minValue = 20
        breakSlider.maxValue = 60
        breakSlider.doubleValue = AppSettings.shared.breakInterval / 60
        breakSlider.numberOfTickMarks = 9
        breakSlider.allowsTickMarkValuesOnly = true
        breakSlider.target = self
        breakSlider.action = #selector(breakSliderChanged(_:))
        breakSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(breakSlider)

        breakValueLabel = label(formatMin(AppSettings.shared.breakInterval), size: 13, weight: .medium, alpha: 1.0)
        view.addSubview(breakValueLabel)

        let breakHint = label("20 min · 20-20-20 rule — recommended by opticians",
                               size: 11, weight: .light, alpha: 0.55)
        view.addSubview(breakHint)

        // ── POSTURE
        let postureHdr = sectionHeader("POSTURE")
        view.addSubview(postureHdr)

        let postureLbl = label("Posture reminders", size: 13, weight: .regular, alpha: 1.0)
        view.addSubview(postureLbl)

        let postureToggle = NSSwitch()
        postureToggle.state = AppSettings.shared.postureEnabled ? .on : .off
        postureToggle.target = self
        postureToggle.action = #selector(postureToggleChanged(_:))
        postureToggle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(postureToggle)

        let postureIntLbl = label("Remind every", size: 12, weight: .regular, alpha: 0.85)
        view.addSubview(postureIntLbl)

        postureIntervalSlider = NSSlider()
        postureIntervalSlider.minValue = 5
        postureIntervalSlider.maxValue = 30
        postureIntervalSlider.doubleValue = AppSettings.shared.postureInterval / 60
        postureIntervalSlider.numberOfTickMarks = 6
        postureIntervalSlider.allowsTickMarkValuesOnly = true
        postureIntervalSlider.isEnabled = AppSettings.shared.postureEnabled
        postureIntervalSlider.target = self
        postureIntervalSlider.action = #selector(postureSliderChanged(_:))
        postureIntervalSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(postureIntervalSlider)

        postureIntervalLabel = label(formatMin(AppSettings.shared.postureInterval),
                                      size: 12, weight: .medium, alpha: 1.0)
        postureIntervalLabel.alphaValue = AppSettings.shared.postureEnabled ? 1.0 : 0.35
        view.addSubview(postureIntervalLabel)

        // ── IDLE DETECTION
        let idleHdr = sectionHeader("IDLE DETECTION")
        view.addSubview(idleHdr)

        let idleLbl = label("Pause when idle for", size: 13, weight: .regular, alpha: 1.0)
        view.addSubview(idleLbl)

        let thresholds: [TimeInterval] = [60, 90, 120]
        let idleSelected = thresholds.firstIndex(of: AppSettings.shared.idleThreshold) ?? 1
        let idleSeg = NSSegmentedControl(labels: ["1 min", "90 sec", "2 min"],
                                          trackingMode: .selectOne,
                                          target: self,
                                          action: #selector(idleSegChanged(_:)))
        idleSeg.selectedSegment = idleSelected
        idleSeg.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(idleSeg)

        // ── SOUND
        let soundHdr = sectionHeader("SOUND")
        view.addSubview(soundHdr)

        let soundSeg = NSSegmentedControl(labels: ["Soothing Music", "Beep Only"],
                                           trackingMode: .selectOne,
                                           target: self,
                                           action: #selector(soundSegChanged(_:)))
        soundSeg.selectedSegment = AppSettings.shared.soundMode == .music ? 0 : 1
        soundSeg.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(soundSeg)

        // ── Constraints
        NSLayoutConstraint.activate([
            titleLbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLbl.topAnchor.constraint(equalTo: view.topAnchor, constant: 52),

            // Eye Break
            eyeHdr.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            eyeHdr.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 30),

            breakLbl.leadingAnchor.constraint(equalTo: eyeHdr.leadingAnchor),
            breakLbl.topAnchor.constraint(equalTo: eyeHdr.bottomAnchor, constant: 12),

            breakSlider.leadingAnchor.constraint(equalTo: breakLbl.trailingAnchor, constant: 12),
            breakSlider.centerYAnchor.constraint(equalTo: breakLbl.centerYAnchor),
            breakSlider.widthAnchor.constraint(equalToConstant: 160),

            breakValueLabel.leadingAnchor.constraint(equalTo: breakSlider.trailingAnchor, constant: 10),
            breakValueLabel.centerYAnchor.constraint(equalTo: breakSlider.centerYAnchor),
            breakValueLabel.widthAnchor.constraint(equalToConstant: 55),

            breakHint.leadingAnchor.constraint(equalTo: eyeHdr.leadingAnchor),
            breakHint.topAnchor.constraint(equalTo: breakLbl.bottomAnchor, constant: 5),

            // Posture
            postureHdr.leadingAnchor.constraint(equalTo: eyeHdr.leadingAnchor),
            postureHdr.topAnchor.constraint(equalTo: breakHint.bottomAnchor, constant: 28),

            postureLbl.leadingAnchor.constraint(equalTo: eyeHdr.leadingAnchor),
            postureLbl.topAnchor.constraint(equalTo: postureHdr.bottomAnchor, constant: 12),

            postureToggle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            postureToggle.centerYAnchor.constraint(equalTo: postureLbl.centerYAnchor),

            postureIntLbl.leadingAnchor.constraint(equalTo: eyeHdr.leadingAnchor, constant: 16),
            postureIntLbl.topAnchor.constraint(equalTo: postureLbl.bottomAnchor, constant: 12),

            postureIntervalSlider.leadingAnchor.constraint(equalTo: postureIntLbl.trailingAnchor, constant: 12),
            postureIntervalSlider.centerYAnchor.constraint(equalTo: postureIntLbl.centerYAnchor),
            postureIntervalSlider.widthAnchor.constraint(equalToConstant: 140),

            postureIntervalLabel.leadingAnchor.constraint(equalTo: postureIntervalSlider.trailingAnchor, constant: 10),
            postureIntervalLabel.centerYAnchor.constraint(equalTo: postureIntervalSlider.centerYAnchor),
            postureIntervalLabel.widthAnchor.constraint(equalToConstant: 55),

            // Idle
            idleHdr.leadingAnchor.constraint(equalTo: eyeHdr.leadingAnchor),
            idleHdr.topAnchor.constraint(equalTo: postureIntLbl.bottomAnchor, constant: 28),

            idleLbl.leadingAnchor.constraint(equalTo: eyeHdr.leadingAnchor),
            idleLbl.topAnchor.constraint(equalTo: idleHdr.bottomAnchor, constant: 12),

            idleSeg.leadingAnchor.constraint(equalTo: idleLbl.trailingAnchor, constant: 12),
            idleSeg.centerYAnchor.constraint(equalTo: idleLbl.centerYAnchor),

            // Sound
            soundHdr.leadingAnchor.constraint(equalTo: eyeHdr.leadingAnchor),
            soundHdr.topAnchor.constraint(equalTo: idleLbl.bottomAnchor, constant: 28),

            soundSeg.leadingAnchor.constraint(equalTo: eyeHdr.leadingAnchor),
            soundSeg.topAnchor.constraint(equalTo: soundHdr.bottomAnchor, constant: 12),
        ])
    }

    // MARK: - Actions

    @objc private func breakSliderChanged(_ s: NSSlider) {
        let mins = s.integerValue
        AppSettings.shared.breakInterval = TimeInterval(mins * 60)
        breakValueLabel.stringValue = "\(mins) min"
        NotificationCenter.default.post(name: .eyeBreakSettingsChanged, object: nil)
    }

    @objc private func postureToggleChanged(_ sw: NSSwitch) {
        let on = sw.state == .on
        AppSettings.shared.postureEnabled = on
        postureIntervalSlider.isEnabled = on
        postureIntervalLabel.alphaValue = on ? 1.0 : 0.35
        NotificationCenter.default.post(name: .postureSettingsChanged, object: nil)
    }

    @objc private func postureSliderChanged(_ s: NSSlider) {
        let mins = s.integerValue
        AppSettings.shared.postureInterval = TimeInterval(mins * 60)
        postureIntervalLabel.stringValue = "\(mins) min"
        NotificationCenter.default.post(name: .postureSettingsChanged, object: nil)
    }

    @objc private func idleSegChanged(_ s: NSSegmentedControl) {
        let thresholds: [TimeInterval] = [60, 90, 120]
        AppSettings.shared.idleThreshold = thresholds[s.selectedSegment]
        NotificationCenter.default.post(name: .eyeBreakSettingsChanged, object: nil)
    }

    @objc private func soundSegChanged(_ s: NSSegmentedControl) {
        AppSettings.shared.soundMode = s.selectedSegment == 0 ? .music : .beep
        NotificationCenter.default.post(name: .eyeBreakSettingsChanged, object: nil)
    }

    // MARK: - Helpers

    private func formatMin(_ interval: TimeInterval) -> String {
        "\(Int(interval / 60)) min"
    }

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight, alpha: CGFloat) -> NSTextField {
        let f = NSTextField(labelWithString: text)
        f.font      = NSFont.systemFont(ofSize: size, weight: weight)
        f.textColor = NSColor.white.withAlphaComponent(alpha)
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }

    private func sectionHeader(_ text: String) -> NSTextField {
        let f = NSTextField(labelWithString: text)
        f.font      = NSFont.systemFont(ofSize: 10, weight: .semibold)
        f.textColor = NSColor(calibratedRed: 0.45, green: 0.72, blue: 1.0, alpha: 0.85)
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }
}
