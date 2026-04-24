import AppKit

class SettingsViewController: NSViewController {

    // MARK: - Child rows that need alpha control
    private var breakChildRows:   [NSView] = []
    private var postureChildRows: [NSView] = []

    // MARK: - Value labels
    private var intervalLabel:        NSTextField!
    private var durationLabel:        NSTextField!
    private var postureIntervalLabel: NSTextField!

    // MARK: - Status pill
    private var statusPillDot:  CALayer!
    private var statusPillText: NSTextField!
    private var statusTimer:    Timer?

    // MARK: - Lifecycle

    override func loadView() {
        let theme  = EmberTheme.dark
        let rootW: CGFloat = 384

        let root = NSView()
        root.wantsLayer = true
        root.layer?.backgroundColor = theme.bg.cgColor

        // ── HEADER ───────────────────────────────────────────
        let header = buildHeader(theme: theme)
        root.addSubview(header)

        // ── BODY ─────────────────────────────────────────────
        let body = buildBody(theme: theme)
        root.addSubview(body)

        // ── FOOTER ───────────────────────────────────────────
        let footer = buildFooter(theme: theme)
        root.addSubview(footer)

        // ── Layout ───────────────────────────────────────────
        header.translatesAutoresizingMaskIntoConstraints = false
        body.translatesAutoresizingMaskIntoConstraints   = false
        footer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: root.topAnchor),
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: root.trailingAnchor),

            body.topAnchor.constraint(equalTo: header.bottomAnchor),
            body.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: root.trailingAnchor),

            footer.topAnchor.constraint(equalTo: body.bottomAnchor),
            footer.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])

        root.frame = NSRect(x: 0, y: 0, width: rootW, height: 630)
        self.view  = root
    }

    override var preferredContentSize: NSSize {
        get { NSSize(width: 384, height: 630) }
        set { }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        updateStats()
        startStatusTimer()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        statusTimer?.invalidate()
        statusTimer = nil
    }

    // MARK: - Header

    private func buildHeader(theme: EmberTheme) -> NSView {
        let header = NSView()
        header.wantsLayer = true

        // Bottom border
        let border = CALayer()
        border.backgroundColor = theme.border.cgColor
        border.autoresizingMask = [.layerWidthSizable]
        header.layer?.addSublayer(border)

        // Eye glyph
        let eye = EyeGlyphView(glyphSize: 16, color: theme.accent)

        // "EyeBreak" label
        let titleLbl = NSTextField(labelWithString: "EyeBreak")
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        titleLbl.font      = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLbl.textColor = theme.text

        // Version label
        let versionLbl = NSTextField(labelWithString: "v2.0")
        versionLbl.translatesAutoresizingMaskIntoConstraints = false
        versionLbl.font      = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        versionLbl.textColor = theme.textDim

        // Left cluster stack
        let leftStack = NSStackView(views: [eye, titleLbl, versionLbl])
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        leftStack.orientation  = .horizontal
        leftStack.spacing      = 9
        leftStack.alignment    = .centerY

        // Status pill
        let pill = buildStatusPill(theme: theme)

        header.addSubview(leftStack)
        header.addSubview(pill)

        NSLayoutConstraint.activate([
            leftStack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 18),
            leftStack.topAnchor.constraint(equalTo: header.topAnchor, constant: 14),
            leftStack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -12),

            pill.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -18),
            pill.centerYAnchor.constraint(equalTo: leftStack.centerYAnchor),
        ])

        // Lay out border after view is sized (deferred)
        DispatchQueue.main.async {
            border.frame = CGRect(x: 0, y: 0, width: header.bounds.width, height: 0.5)
        }

        return header
    }

    private func buildStatusPill(theme: EmberTheme) -> NSView {
        let pill = NSView()
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.wantsLayer = true
        pill.layer?.backgroundColor = theme.accentSoft.cgColor
        pill.layer?.cornerRadius    = 99

        // Dot layer
        let dot = CALayer()
        dot.frame           = CGRect(x: 7, y: 7, width: 6, height: 6)
        dot.cornerRadius    = 3
        dot.backgroundColor = theme.accent.cgColor
        dot.shadowColor     = theme.accent.cgColor
        dot.shadowOpacity   = 0.8
        dot.shadowRadius    = 3
        dot.shadowOffset    = .zero
        pill.layer?.addSublayer(dot)
        self.statusPillDot = dot

        let pillText = NSTextField(labelWithString: "next in --")
        pillText.translatesAutoresizingMaskIntoConstraints = false
        pillText.font      = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        pillText.textColor = theme.accent
        pill.addSubview(pillText)
        self.statusPillText = pillText

        NSLayoutConstraint.activate([
            pill.heightAnchor.constraint(equalToConstant: 20),

            pillText.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 20),
            pillText.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -9),
            pillText.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
        ])

        return pill
    }

    private func startStatusTimer() {
        updateStatusPill()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.updateStatusPill()
        }
        RunLoop.main.add(statusTimer!, forMode: .common)
    }

    private func updateStatusPill() {
        // BreakController exposes secondsUntilBreakPublic and isPausedPublic
        guard let bc = (NSApp.delegate as? AppDelegate)?.breakControllerPublic else { return }
        let theme = EmberTheme.dark
        if bc.isPausedPublic || !AppSettings.shared.breakEnabled {
            statusPillText?.stringValue = "paused"
            statusPillText?.textColor   = theme.textMuted
            statusPillDot?.backgroundColor = theme.textMuted.cgColor
            statusPillDot?.shadowOpacity   = 0
        } else {
            let secs = bc.secondsUntilBreakPublic
            let text: String
            if secs > 60 {
                text = "next in \(secs / 60)m"
            } else if secs > 0 {
                text = "next in \(secs)s"
            } else {
                text = "now"
            }
            statusPillText?.stringValue    = text
            statusPillText?.textColor      = theme.accent
            statusPillDot?.backgroundColor = theme.accent.cgColor
            statusPillDot?.shadowOpacity   = 0.8
        }
    }

    // MARK: - Body

    private func buildBody(theme: EmberTheme) -> NSView {
        let body = NSView()
        body.wantsLayer = true

        // We build a vertical stack of rows inside a scroll-less container
        let stack = NSStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation  = .vertical
        stack.alignment    = .leading
        stack.spacing      = 0
        stack.distribution = .fill
        body.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: body.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: body.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: body.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: body.bottomAnchor, constant: -6),
        ])

        // ── EYE BREAK ─────────────────────────────────────
        stack.addArrangedSubview(sectionLabel("Eye Break", theme: theme))

        let breakToggle = EmberToggle(size: .md, isOn: AppSettings.shared.breakEnabled)
        breakToggle.onChange = { [weak self] on in
            AppSettings.shared.breakEnabled = on
            self?.setBreakChildrenAlpha(on ? 1.0 : 0.4)
            NotificationCenter.default.post(name: .eyeBreakSettingsChanged, object: nil)
        }
        stack.addArrangedSubview(row(
            label: "Break reminders",
            hint:  "20-20-20 rule — recommended by opticians",
            right: breakToggle,
            tight: false,
            theme: theme
        ))

        // Interval row
        let intervalVal  = Int(AppSettings.shared.breakInterval / 60)
        intervalLabel    = monoLabel("\(intervalVal) min", theme: theme)
        let intervalSlider = EmberSlider(
            value:    Double(intervalVal),
            minValue: 10, maxValue: 60, step: 5
        )
        intervalSlider.onChange = { [weak self] val in
            let mins = Int(val)
            AppSettings.shared.breakInterval = TimeInterval(mins * 60)
            self?.intervalLabel.stringValue  = "\(mins) min"
            NotificationCenter.default.post(name: .eyeBreakSettingsChanged, object: nil)
        }
        let intervalRight = sliderWithLabel(slider: intervalSlider, label: intervalLabel)
        let intervalRow = row(label: "Interval", hint: nil, right: intervalRight, tight: true, theme: theme)
        breakChildRows.append(intervalRow)
        stack.addArrangedSubview(intervalRow)

        // Duration row
        let durationVal  = AppSettings.shared.breakDuration
        durationLabel    = monoLabel("\(durationVal) sec", theme: theme)
        let durationSlider = EmberSlider(
            value:    Double(durationVal),
            minValue: 10, maxValue: 60, step: 5
        )
        durationSlider.onChange = { [weak self] val in
            let secs = Int(val)
            AppSettings.shared.breakDuration = secs
            self?.durationLabel.stringValue  = "\(secs) sec"
        }
        let durationRight = sliderWithLabel(slider: durationSlider, label: durationLabel)
        let durationRow = row(label: "Duration", hint: nil, right: durationRight, tight: true, theme: theme)
        breakChildRows.append(durationRow)
        stack.addArrangedSubview(durationRow)

        setBreakChildrenAlpha(AppSettings.shared.breakEnabled ? 1.0 : 0.4)

        stack.addArrangedSubview(divider(theme: theme))

        // ── POSTURE ───────────────────────────────────────
        stack.addArrangedSubview(sectionLabel("Posture", theme: theme))

        let postureToggle = EmberToggle(size: .md, isOn: AppSettings.shared.postureEnabled)
        postureToggle.onChange = { [weak self] on in
            AppSettings.shared.postureEnabled = on
            self?.setPostureChildrenAlpha(on ? 1.0 : 0.4)
            NotificationCenter.default.post(name: .postureSettingsChanged, object: nil)
        }
        stack.addArrangedSubview(row(
            label: "Posture nudges",
            hint:  nil,
            right: postureToggle,
            tight: false,
            theme: theme
        ))

        let postureIntVal = Int(AppSettings.shared.postureInterval / 60)
        postureIntervalLabel = monoLabel("\(postureIntVal) min", theme: theme)
        let postureSlider = EmberSlider(
            value:    Double(postureIntVal),
            minValue: 5, maxValue: 30, step: 5
        )
        postureSlider.onChange = { [weak self] val in
            let mins = Int(val)
            AppSettings.shared.postureInterval       = TimeInterval(mins * 60)
            self?.postureIntervalLabel.stringValue   = "\(mins) min"
            NotificationCenter.default.post(name: .postureSettingsChanged, object: nil)
        }
        let postureIntRight = sliderWithLabel(slider: postureSlider, label: postureIntervalLabel)
        let postureIntRow = row(label: "Remind every", hint: nil, right: postureIntRight, tight: true, theme: theme)
        postureChildRows.append(postureIntRow)
        stack.addArrangedSubview(postureIntRow)

        setPostureChildrenAlpha(AppSettings.shared.postureEnabled ? 1.0 : 0.4)

        stack.addArrangedSubview(divider(theme: theme))

        // ── IDLE DETECTION ────────────────────────────────
        stack.addArrangedSubview(sectionLabel("Idle detection", theme: theme))

        let currentIdle   = String(Int(AppSettings.shared.idleThreshold))
        let idleSeg = EmberSegmented(options: [
            EmberSegmented.Option(value: "60",  label: "1 min"),
            EmberSegmented.Option(value: "90",  label: "90s"),
            EmberSegmented.Option(value: "120", label: "2 min"),
        ], selected: currentIdle)
        idleSeg.onSelect = { val in
            AppSettings.shared.idleThreshold = TimeInterval(Int(val) ?? 90)
            NotificationCenter.default.post(name: .eyeBreakSettingsChanged, object: nil)
        }
        stack.addArrangedSubview(row(
            label: "Pause when idle for",
            hint:  nil,
            right: idleSeg,
            tight: false,
            theme: theme
        ))

        stack.addArrangedSubview(divider(theme: theme))

        // ── SOUND ─────────────────────────────────────────
        stack.addArrangedSubview(sectionLabel("Sound", theme: theme))

        let soundSeg = EmberSegmented(options: [
            EmberSegmented.Option(value: "music",  label: "Soothing"),
            EmberSegmented.Option(value: "beep",   label: "Beep"),
            EmberSegmented.Option(value: "silent", label: "Silent"),
        ], selected: AppSettings.shared.soundMode.rawValue)
        soundSeg.onSelect = { val in
            AppSettings.shared.soundMode = SoundMode(rawValue: val) ?? .music
            NotificationCenter.default.post(name: .eyeBreakSettingsChanged, object: nil)
        }
        stack.addArrangedSubview(row(
            label: "Break cue",
            hint:  nil,
            right: soundSeg,
            tight: false,
            theme: theme
        ))

        stack.addArrangedSubview(divider(theme: theme))

        // ── GENERAL ───────────────────────────────────────
        stack.addArrangedSubview(sectionLabel("General", theme: theme))

        let loginToggle = EmberToggle(size: .sm, isOn: NotificationManager.shared.loginItemIsActive)
        loginToggle.onChange = { on in
            AppSettings.shared.startAtLogin = on
            NotificationManager.shared.applyLoginItem(enabled: on)
        }
        stack.addArrangedSubview(row(label: "Start at login", hint: nil, right: loginToggle, tight: true, theme: theme))

        let notifToggle = EmberToggle(size: .sm, isOn: AppSettings.shared.showInNotifCenter)
        notifToggle.onChange = { on in AppSettings.shared.showInNotifCenter = on }
        stack.addArrangedSubview(row(label: "Show in Notification Center", hint: nil, right: notifToggle, tight: true, theme: theme))

        let dndToggle = EmberToggle(size: .sm, isOn: AppSettings.shared.respectDnD)
        dndToggle.onChange = { on in AppSettings.shared.respectDnD = on }
        stack.addArrangedSubview(row(label: "Respect Do Not Disturb", hint: nil, right: dndToggle, tight: true, theme: theme))

        return body
    }

    // MARK: - Footer

    private func buildFooter(theme: EmberTheme) -> NSView {
        let footer = NSView()
        footer.wantsLayer = true
        footer.layer?.backgroundColor = theme.bgSunken.cgColor

        // Top border
        let border = CALayer()
        border.backgroundColor = theme.border.cgColor
        border.autoresizingMask = [.layerWidthSizable]
        border.frame = CGRect(x: 0, y: 0, width: 384, height: 0.5)
        footer.layer?.addSublayer(border)

        // Three stat items side-by-side, centred, with dividers between them
        let todayStat   = statItem(value: "\(StatsManager.shared.todayCount)",    label: "today",       theme: theme)
        let streakStat  = statItem(value: "\(StatsManager.shared.streakDays)",    label: "day streak",  theme: theme)
        let restedStat  = statItem(value: StatsManager.shared.todayRestFormatted, label: "eyes rested", theme: theme)

        let div1 = statDivider(theme: theme)
        let div2 = statDivider(theme: theme)

        let statsStack = NSStackView(views: [todayStat, div1, streakStat, div2, restedStat])
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        statsStack.orientation  = .horizontal
        statsStack.alignment    = .centerY
        statsStack.spacing      = 0
        footer.addSubview(statsStack)

        NSLayoutConstraint.activate([
            statsStack.centerXAnchor.constraint(equalTo: footer.centerXAnchor),
            statsStack.topAnchor.constraint(equalTo: footer.topAnchor, constant: 12),
            statsStack.bottomAnchor.constraint(equalTo: footer.bottomAnchor, constant: -12),
        ])

        return footer
    }

    // MARK: - Stats update

    private func updateStats() {
        StatsManager.shared.checkMidnightReset()
        // The footer is rebuilt on viewWillAppear, so values are always fresh
    }

    // MARK: - Helpers

    private func setBreakChildrenAlpha(_ alpha: CGFloat) {
        breakChildRows.forEach { $0.alphaValue = alpha }
    }

    private func setPostureChildrenAlpha(_ alpha: CGFloat) {
        postureChildRows.forEach { $0.alphaValue = alpha }
    }

    private func sectionLabel(_ text: String, theme: EmberTheme) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let str = NSMutableAttributedString(string: text.uppercased())
        str.addAttribute(.font,            value: NSFont.systemFont(ofSize: 10, weight: .semibold), range: NSRange(location: 0, length: str.length))
        str.addAttribute(.foregroundColor, value: theme.label,  range: NSRange(location: 0, length: str.length))
        str.addAttribute(.kern,            value: 1.2 as NSNumber, range: NSRange(location: 0, length: str.length))
        let lbl = NSTextField(labelWithAttributedString: str)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(lbl)

        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: container.topAnchor),
            lbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            lbl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            lbl.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
        ])

        return container
    }

    private func row(label: String, hint: String?, right: NSView, tight: Bool, theme: EmberTheme) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let labelLbl = NSTextField(labelWithString: label)
        labelLbl.translatesAutoresizingMaskIntoConstraints = false
        labelLbl.font      = NSFont.systemFont(ofSize: 13, weight: .medium)
        labelLbl.textColor = theme.text
        container.addSubview(labelLbl)

        right.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(right)

        var constraints: [NSLayoutConstraint] = [
            labelLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelLbl.topAnchor.constraint(equalTo: container.topAnchor),

            right.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            right.centerYAnchor.constraint(equalTo: labelLbl.centerYAnchor),
            right.leadingAnchor.constraint(greaterThanOrEqualTo: labelLbl.trailingAnchor, constant: 8),
        ]

        if let hint = hint {
            let hintLbl = NSTextField(labelWithString: hint)
            hintLbl.translatesAutoresizingMaskIntoConstraints = false
            hintLbl.font            = NSFont.systemFont(ofSize: 11, weight: .regular)
            hintLbl.textColor       = theme.textMuted
            hintLbl.lineBreakMode   = .byWordWrapping
            hintLbl.maximumNumberOfLines = 2
            container.addSubview(hintLbl)
            constraints += [
                hintLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                hintLbl.topAnchor.constraint(equalTo: labelLbl.bottomAnchor, constant: 3),
                hintLbl.trailingAnchor.constraint(lessThanOrEqualTo: right.leadingAnchor, constant: -8),
                hintLbl.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -(tight ? 10 : 14)),
            ]
        } else {
            constraints.append(
                labelLbl.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -(tight ? 10 : 14))
            )
        }

        NSLayoutConstraint.activate(constraints)
        return container
    }

    private func divider(theme: EmberTheme) -> NSView {
        let v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.wantsLayer = true
        v.layer?.backgroundColor = theme.border.cgColor
        NSLayoutConstraint.activate([
            v.heightAnchor.constraint(equalToConstant: 0.5),
        ])
        // Margins via a wrapper
        let wrapper = NSView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 18),
            v.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            v.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -18),
        ])
        return wrapper
    }

    private func monoLabel(_ text: String, theme: EmberTheme) -> NSTextField {
        let lbl = NSTextField(labelWithString: text)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font      = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        lbl.textColor = theme.text
        lbl.alignment = .right
        NSLayoutConstraint.activate([
            lbl.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
        return lbl
    }

    private func sliderWithLabel(slider: EmberSlider, label: NSTextField) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints  = false
        container.addSubview(slider)
        container.addSubview(label)
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            slider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            slider.widthAnchor.constraint(equalToConstant: 160),

            label.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 10),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            container.heightAnchor.constraint(equalToConstant: 18),
        ])
        return container
    }

    private func statItem(value: String, label: String, theme: EmberTheme) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let valueLbl = NSTextField(labelWithString: value)
        valueLbl.translatesAutoresizingMaskIntoConstraints = false
        valueLbl.font      = NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
        valueLbl.textColor = theme.text
        valueLbl.alignment = .center

        let labelStr = NSMutableAttributedString(string: label.uppercased())
        labelStr.addAttribute(.font,            value: NSFont.systemFont(ofSize: 9, weight: .medium),
                               range: NSRange(location: 0, length: labelStr.length))
        labelStr.addAttribute(.foregroundColor, value: theme.textDim,
                               range: NSRange(location: 0, length: labelStr.length))
        labelStr.addAttribute(.kern,            value: 0.6 as NSNumber,
                               range: NSRange(location: 0, length: labelStr.length))
        let labelLbl = NSTextField(labelWithAttributedString: labelStr)
        labelLbl.translatesAutoresizingMaskIntoConstraints = false
        labelLbl.alignment = .center

        container.addSubview(valueLbl)
        container.addSubview(labelLbl)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 96),

            valueLbl.topAnchor.constraint(equalTo: container.topAnchor),
            valueLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            valueLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            labelLbl.topAnchor.constraint(equalTo: valueLbl.bottomAnchor, constant: 3),
            labelLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            labelLbl.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    private func statDivider(theme: EmberTheme) -> NSView {
        let v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.wantsLayer = true
        v.layer?.backgroundColor = theme.border.cgColor
        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: 0.5),
            v.heightAnchor.constraint(equalToConstant: 28),
        ])
        return v
    }
}
