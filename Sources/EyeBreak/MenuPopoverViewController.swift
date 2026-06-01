import AppKit

// MARK: - Action Row

private class ActionRow: NSView {
    var action: (() -> Void)?

    private let hoverLayer = CALayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        hoverLayer.backgroundColor = NSColor(white: 1, alpha: 0.055).cgColor
        hoverLayer.opacity = 0
        layer?.addSublayer(hoverLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        hoverLayer.frame = bounds
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.mouseEnteredAndExited, .activeAlways],
                                       owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) { hoverLayer.opacity = 1 }
    override func mouseExited(with event: NSEvent)  { hoverLayer.opacity = 0 }
    override func mouseDown(with event: NSEvent)    {}
    override func mouseUp(with event: NSEvent)      { action?() }
}

// MARK: - MenuPopoverViewController

class MenuPopoverViewController: NSViewController {

    // Callbacks wired by AppDelegate
    var onTakeBreak:    (() -> Void)?
    var onSkipBreak:    (() -> Void)?
    var onPauseHour:    (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onShowAbout:    (() -> Void)?
    var onUnlock:       (() -> Void)?

    // Reference to own popover for programmatic close
    weak var popover: NSPopover?

    // Subviews refreshed on a timer
    private var ringsView:    ActivityRingsView!
    private var statLine1:    NSTextField!
    private var statLine2:    NSTextField!
    private var statLine3:    NSTextField!
    private var insightLabel: NSTextField!
    private var trialBadge:   NSTextField!

    private var refreshTimer: Timer?
    private var insightIndex = 0

    private let theme = EmberTheme.dark
    static let width: CGFloat = 380

    // MARK: - View

    override func loadView() {
        let root = NSView()
        root.wantsLayer = true
        root.layer?.backgroundColor = theme.bg.cgColor

        let header  = buildHeader()
        let stats   = buildStatsSection()
        let divider = buildDivider()
        let actions = buildActionsSection()

        [header, stats, divider, actions].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview($0)
        }

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: root.topAnchor),
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: root.trailingAnchor),

            stats.topAnchor.constraint(equalTo: header.bottomAnchor),
            stats.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stats.trailingAnchor.constraint(equalTo: root.trailingAnchor),

            divider.topAnchor.constraint(equalTo: stats.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            actions.topAnchor.constraint(equalTo: divider.bottomAnchor),
            actions.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            actions.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            actions.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])

        root.frame = NSRect(x: 0, y: 0, width: Self.width, height: 1)
        self.view = root
    }

    override var preferredContentSize: NSSize {
        get {
            let needsUnlock = TrialManager.shared.isTrialExpired
            let actionH: CGFloat = needsUnlock ? 284 : 244
            return NSSize(width: Self.width, height: 44 + 144 + 1 + actionH)
        }
        set {}
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        advanceInsight()
        refreshStats()
        startTimers()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        stopTimers()
    }

    // MARK: - Header

    private func buildHeader() -> NSView {
        let header = NSView()
        header.wantsLayer = true

        let bottomBorder = CALayer()
        bottomBorder.backgroundColor = theme.border.cgColor
        bottomBorder.autoresizingMask = [.layerWidthSizable]
        header.layer?.addSublayer(bottomBorder)
        DispatchQueue.main.async { bottomBorder.frame = CGRect(x: 0, y: 0, width: header.bounds.width, height: 0.5) }

        let eye      = EyeGlyphView(glyphSize: 14, color: theme.accent)
        let titleLbl = NSTextField(labelWithString: "IrisBreak")
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        titleLbl.font      = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLbl.textColor = theme.text

        let leftStack = NSStackView(views: [eye, titleLbl])
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        leftStack.orientation = .horizontal
        leftStack.spacing     = 8
        leftStack.alignment   = .centerY

        let badge = buildTrialBadge()
        self.trialBadge = badge

        let rightStack = NSStackView(views: [badge])
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        rightStack.orientation = .horizontal
        rightStack.spacing     = 8
        rightStack.alignment   = .centerY

        if !TrialManager.shared.isPurchased {
            let buyBtn = NSButton(title: "Buy", target: self, action: #selector(buyTapped))
            buyBtn.translatesAutoresizingMaskIntoConstraints = false
            buyBtn.isBordered       = false
            buyBtn.wantsLayer       = true
            buyBtn.layer?.backgroundColor = theme.accentSoft.cgColor
            buyBtn.layer?.cornerRadius    = 9
            buyBtn.attributedTitle  = NSAttributedString(
                string: "Buy",
                attributes: [
                    .foregroundColor: theme.accent,
                    .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                ])
            buyBtn.heightAnchor.constraint(equalToConstant: 18).isActive = true
            buyBtn.widthAnchor.constraint(greaterThanOrEqualToConstant: 38).isActive = true
            rightStack.addArrangedSubview(buyBtn)
        }

        header.addSubview(leftStack)
        header.addSubview(rightStack)

        NSLayoutConstraint.activate([
            leftStack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 14),
            leftStack.topAnchor.constraint(equalTo: header.topAnchor, constant: 13),
            leftStack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -11),

            rightStack.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -14),
            rightStack.centerYAnchor.constraint(equalTo: leftStack.centerYAnchor),
        ])

        return header
    }

    private func buildTrialBadge() -> NSTextField {
        let trial = TrialManager.shared
        let text: String; let color: NSColor
        if trial.isPurchased {
            text = "✓ Licensed"; color = NSColor(calibratedRed: 0.35, green: 0.85, blue: 0.55, alpha: 1)
        } else if trial.isTrialActive {
            text = "\(trial.daysRemaining)d trial"; color = theme.accent
        } else {
            text = "Trial ended"; color = NSColor(calibratedRed: 1, green: 0.45, blue: 0.4, alpha: 1)
        }
        let lbl = NSTextField(labelWithString: text)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font      = NSFont.systemFont(ofSize: 11, weight: .medium)
        lbl.textColor = color
        return lbl
    }

    // MARK: - Stats Section

    private func buildStatsSection() -> NSView {
        let container = NSView()

        let rings = ActivityRingsView()
        rings.translatesAutoresizingMaskIntoConstraints = false
        rings.centerText = "—"
        self.ringsView = rings
        container.addSubview(rings)

        let right = buildStatsRight()
        right.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(right)

        NSLayoutConstraint.activate([
            rings.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            rings.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            rings.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            rings.widthAnchor.constraint(equalToConstant: 112),
            rings.heightAnchor.constraint(equalToConstant: 112),

            right.leadingAnchor.constraint(equalTo: rings.trailingAnchor, constant: 14),
            right.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            right.centerYAnchor.constraint(equalTo: rings.centerYAnchor),
            right.widthAnchor.constraint(equalToConstant: 214),
        ])

        if TrialManager.shared.isTrialExpired {
            rings.alphaValue = 0.08
            right.alphaValue = 0.08
            let overlay = buildStatsLockOverlay()
            overlay.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(overlay)
            NSLayoutConstraint.activate([
                overlay.topAnchor.constraint(equalTo: container.topAnchor),
                overlay.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                overlay.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
        }

        return container
    }

    private func buildStatsLockOverlay() -> NSView {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = theme.bg.withAlphaComponent(0.90).cgColor

        let lockImg = NSImageView()
        if let img = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil) {
            lockImg.image = img.withSymbolConfiguration(
                NSImage.SymbolConfiguration(pointSize: 15, weight: .medium))
        }
        lockImg.contentTintColor = theme.accent
        lockImg.translatesAutoresizingMaskIntoConstraints = false

        let text = NSTextField(labelWithString: "Unlock IrisBreak to see your stats")
        text.translatesAutoresizingMaskIntoConstraints = false
        text.font      = NSFont.systemFont(ofSize: 12, weight: .regular)
        text.textColor = theme.textMuted
        text.alignment = .center

        let btn = NSButton(title: "Unlock IrisBreak — $4.99", target: self, action: #selector(unlockFromStats))
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isBordered       = false
        btn.contentTintColor = theme.accent
        btn.font             = NSFont.systemFont(ofSize: 13, weight: .semibold)

        let stack = NSStackView(views: [lockImg, text, btn])
        stack.orientation = .vertical
        stack.spacing     = 5
        stack.alignment   = .centerX
        stack.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: v.centerYAnchor),
        ])

        return v
    }

    @objc private func unlockFromStats() {
        closeThenRun { $0.onUnlock?() }
    }

    @objc private func buyTapped() {
        closeThenRun { $0.onUnlock?() }
    }

    private func buildStatsRight() -> NSView {
        let stack = NSStackView()
        stack.orientation  = .vertical
        stack.alignment    = .leading
        stack.spacing      = 5

        // Order: inner ring first (most visible, closest to countdown center)
        let (row1, lbl1) = dotRow(dot: ActivityRingsView.innerColor,  text: restedText())
        let (row2, lbl2) = dotRow(dot: ActivityRingsView.middleColor, text: breaksText())
        let (row3, lbl3) = dotRow(dot: ActivityRingsView.outerColor,  text: weekText())
        self.statLine1 = lbl1
        self.statLine2 = lbl2
        self.statLine3 = lbl3

        let miniDiv = NSView()
        miniDiv.translatesAutoresizingMaskIntoConstraints = false
        miniDiv.wantsLayer = true
        miniDiv.layer?.backgroundColor = theme.border.cgColor

        let insight = NSTextField(labelWithString: currentInsight())
        insight.translatesAutoresizingMaskIntoConstraints = false
        insight.font                    = NSFont.systemFont(ofSize: 11, weight: .regular)
        insight.textColor               = theme.textMuted
        insight.maximumNumberOfLines    = 2
        insight.lineBreakMode           = .byWordWrapping
        insight.preferredMaxLayoutWidth = 202
        insight.setContentHuggingPriority(.defaultLow, for: .horizontal)
        self.insightLabel = insight

        [row1, row2, row3].forEach { stack.addArrangedSubview($0) }
        stack.addArrangedSubview(miniDiv)
        stack.addArrangedSubview(insight)

        miniDiv.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        miniDiv.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        return stack
    }

    private func dotRow(dot: NSColor, text: String) -> (NSView, NSTextField) {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let dotV = NSView()
        dotV.translatesAutoresizingMaskIntoConstraints = false
        dotV.wantsLayer = true
        dotV.layer?.backgroundColor = dot.cgColor
        dotV.layer?.cornerRadius = 3

        let lbl = NSTextField(labelWithString: text)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font      = NSFont.systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = theme.text

        container.addSubview(dotV)
        container.addSubview(lbl)

        NSLayoutConstraint.activate([
            dotV.widthAnchor.constraint(equalToConstant: 6),
            dotV.heightAnchor.constraint(equalToConstant: 6),
            dotV.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dotV.centerYAnchor.constraint(equalTo: lbl.centerYAnchor),

            lbl.leadingAnchor.constraint(equalTo: dotV.trailingAnchor, constant: 7),
            lbl.topAnchor.constraint(equalTo: container.topAnchor),
            lbl.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            lbl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        return (container, lbl)
    }

    // MARK: - Divider

    private func buildDivider() -> NSView {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = theme.border.cgColor
        return v
    }

    // MARK: - Actions Section

    private func buildActionsSection() -> NSView {
        let stack = NSStackView()
        stack.orientation  = .vertical
        stack.alignment    = .leading
        stack.spacing      = 0
        stack.translatesAutoresizingMaskIntoConstraints = false

        func pad(_ h: CGFloat) {
            let v = NSView(); v.translatesAutoresizingMaskIntoConstraints = false
            v.heightAnchor.constraint(equalToConstant: h).isActive = true
            v.widthAnchor.constraint(equalToConstant: Self.width).isActive = true
            stack.addArrangedSubview(v)
        }

        let expired = TrialManager.shared.isTrialExpired
        pad(5)
        addRow("Take Break Now",   key: "⌘B", action: { [weak self] in self?.closeThenRun { $0.onTakeBreak?() } }, to: stack, disabled: expired)
        addRow("Skip Next Break",  key: "⌘S", action: { [weak self] in self?.closeThenRun { $0.onSkipBreak?() } }, to: stack, disabled: expired)
        addRow("Pause for 1 Hour", key: "⌘P", action: { [weak self] in self?.closeThenRun { $0.onPauseHour?() } }, to: stack, disabled: expired)
        stack.addArrangedSubview(actionSep())
        addRow("Settings…",        key: "⌘,", action: { [weak self] in self?.closeThenRun { $0.onOpenSettings?() } }, to: stack)
        addRow("About IrisBreak",   key: "",   action: { [weak self] in self?.closeThenRun { $0.onShowAbout?() } }, to: stack)

        if TrialManager.shared.isTrialExpired {
            stack.addArrangedSubview(actionSep())
            addRow("Unlock IrisBreak — $4.99", key: "", action: { [weak self] in self?.closeThenRun { $0.onUnlock?() } },
                   to: stack, accent: true)
        }

        stack.addArrangedSubview(actionSep())
        addRow("Quit IrisBreak", key: "⌘Q", action: { NSApp.terminate(nil) }, to: stack, dim: true)
        pad(5)

        let wrapper = NSView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: wrapper.topAnchor),
            stack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])
        return wrapper
    }

    private func addRow(_ title: String, key: String, action: @escaping () -> Void,
                        to stack: NSStackView, accent: Bool = false, dim: Bool = false, disabled: Bool = false) {
        let row = ActionRow()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.action = disabled ? nil : action
        row.alphaValue = disabled ? 0.35 : 1.0

        let color: NSColor = accent ? theme.accent : (dim ? theme.textMuted : theme.text)
        let titleLbl = NSTextField(labelWithString: title)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        titleLbl.font      = NSFont.systemFont(ofSize: 13, weight: accent ? .medium : .regular)
        titleLbl.textColor = color

        let keyLbl = NSTextField(labelWithString: key)
        keyLbl.translatesAutoresizingMaskIntoConstraints = false
        keyLbl.font      = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        keyLbl.textColor = theme.textDim
        keyLbl.alignment = .right

        row.addSubview(titleLbl)
        row.addSubview(keyLbl)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 30),
            row.widthAnchor.constraint(equalToConstant: Self.width),

            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 14),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            keyLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -14),
            keyLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])

        stack.addArrangedSubview(row)
    }

    private func actionSep() -> NSView {
        let inner = NSView()
        inner.translatesAutoresizingMaskIntoConstraints = false
        inner.wantsLayer = true
        inner.layer?.backgroundColor = theme.border.cgColor

        let wrapper = NSView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.heightAnchor.constraint(equalToConstant: 0.5),
            inner.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 3),
            inner.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            inner.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            inner.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -3),
            wrapper.widthAnchor.constraint(equalToConstant: Self.width),
        ])
        return wrapper
    }

    private func closeThenRun(_ block: @escaping (MenuPopoverViewController) -> Void) {
        popover?.close()
        block(self)
    }

    // MARK: - Timers

    private func startTimers() {
        refreshStats()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refreshStats()
        }
        RunLoop.main.add(refreshTimer!, forMode: .common)
    }

    private func stopTimers() {
        refreshTimer?.invalidate(); refreshTimer = nil
    }

    // MARK: - Refresh

    private func refreshStats() {
        let s = StatsManager.shared
        s.checkMidnightReset()

        ringsView.outerProgress  = s.weekConsistencyProgress
        ringsView.middleProgress = s.todayBreaksProgress
        ringsView.innerProgress  = s.todayRestedProgress

        statLine1.stringValue = restedText()
        statLine2.stringValue = breaksText()
        statLine3.stringValue = weekText()

        if let bc = (NSApp.delegate as? AppDelegate)?.breakControllerPublic {
            if bc.isPausedPublic {
                ringsView.centerText = "—"
            } else {
                let secs = bc.secondsUntilBreakPublic
                ringsView.centerText = secs > 60 ? "\(secs / 60)m" : "\(secs)s"
            }
        }
    }

    // MARK: - Insight

    private func advanceInsight() {
        insightIndex = (insightIndex + 1) % allInsights.count
        insightLabel?.stringValue = allInsights[insightIndex]
    }

    private func currentInsight() -> String { allInsights[0] }

    private var allInsights: [String] {
        let s = StatsManager.shared
        return [
            "You've rested your eyes \(s.todayRestFormatted) today. Most desk workers: 0.",
            "Every break reduces digital eye strain by up to 40%.",
            "20-20-20: look 20 feet away for 20 seconds, every 20 minutes.",
            "\(s.streakDays > 0 ? "\(s.streakDays)-day streak — keep going." : "Start your streak — take a break today.")",
            "Your eyes refocus up to 10,000 times per working day.",
            "Goal: \(StatsManager.dailyBreakGoal) breaks a day. You've done \(s.todayCount).",
            "Blue light from screens suppresses melatonin — breaks help your sleep too.",
            "The ciliary muscles in your eyes need rest just like any other muscle.",
        ]
    }

    // MARK: - Stat text helpers

    private func weekText() -> String {
        let pct = Int(StatsManager.shared.weekConsistencyProgress * 100)
        return "Week streak  \(pct)%"
    }

    private func breaksText() -> String {
        let s = StatsManager.shared
        return "Breaks today  \(s.todayCount)/\(StatsManager.dailyBreakGoal)"
    }

    private func restedText() -> String {
        return "Eyes rested  \(StatsManager.shared.todayRestFormatted)"
    }
}
