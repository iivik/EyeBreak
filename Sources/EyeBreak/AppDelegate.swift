import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    var breakControllerPublic: BreakController!
    private var postureController: PostureController!
    private var warningBanner: WarningBannerController!
    private var rewardBanner = BreakRewardBannerController()

    // Main menu popover (replaces NSMenu dropdown)
    private var menuPopover:        NSPopover?
    private var menuPopoverVC:      MenuPopoverViewController?
    private var outsideClickMonitor: Any?

    // Settings popover (unchanged)
    private var settingsPopover: NSPopover?
    private var settingsVC:      SettingsViewController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        breakControllerPublic = BreakController()
        postureController     = PostureController()
        warningBanner         = WarningBannerController()

        setupStatusBar()
        wireCallbacks()
        observeSettings()

        breakControllerPublic.start()
        postureController.start()

        NotificationManager.shared.requestPermission()
        OnboardingController.showIfNeeded(after: 1.2)
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.imagePosition = .imageLeft
            updateStatusBarIcon()
            button.title = "  20m"
            button.font  = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
            button.target = self
            button.action = #selector(handleStatusBarClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        // Do NOT set statusItem.menu — clicks go through the button action instead
    }

    private func updateStatusBarIcon() {
        guard let button = statusItem.button else { return }
        let size: CGFloat = 16
        let img = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let color = NSColor.white
            let s = size / 20.0
            ctx.translateBy(x: 0, y: rect.height)
            ctx.scaleBy(x: s, y: -s)

            let path = CGMutablePath()
            path.move(to: CGPoint(x: 1.5, y: 10))
            path.addCurve(to: CGPoint(x: 10, y: 3.5),
                          control1: CGPoint(x: 4, y: 5), control2: CGPoint(x: 7, y: 3.5))
            path.addCurve(to: CGPoint(x: 18.5, y: 10),
                          control1: CGPoint(x: 13, y: 3.5), control2: CGPoint(x: 16, y: 5))
            path.addCurve(to: CGPoint(x: 10, y: 16.5),
                          control1: CGPoint(x: 16, y: 15), control2: CGPoint(x: 13, y: 16.5))
            path.addCurve(to: CGPoint(x: 1.5, y: 10),
                          control1: CGPoint(x: 7, y: 16.5), control2: CGPoint(x: 4, y: 15))
            path.closeSubpath()
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(1.3 / s)
            ctx.addPath(path)
            ctx.strokePath()

            let pr: CGFloat = 2.7
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: CGRect(x: 10 - pr, y: 10 - pr, width: pr * 2, height: pr * 2))
            return true
        }
        img.isTemplate = true
        button.image = img
    }

    private func updateMenuBarTitle(_ countdown: String) {
        statusItem.button?.title = "  \(countdown)\(TrialManager.shared.statusLabel)"
    }

    // MARK: - Status Bar Click

    @objc private func handleStatusBarClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Right-click: show a lightweight context menu (same actions as popover)
            statusItem.menu = buildContextMenu()
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            toggleMenuPopover()
        }
    }

    @objc private func toggleMenuPopover() {
        if let pop = menuPopover, pop.isShown {
            pop.close()
            return
        }
        ensureMenuPopover()
        guard let button = statusItem.button else { return }
        menuPopover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // Global monitor so clicking any other app dismisses the popover
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            DispatchQueue.main.async { self?.menuPopover?.close() }
        }
    }

    private func ensureMenuPopover() {
        if menuPopover != nil { return }

        let vc = MenuPopoverViewController()
        menuPopoverVC = vc

        vc.onTakeBreak    = { [weak self] in self?.warningBanner.dismiss(); self?.breakControllerPublic.triggerNow() }
        vc.onSkipBreak    = { [weak self] in self?.breakControllerPublic.skipNextBreak() }
        vc.onPauseHour    = { [weak self] in self?.breakControllerPublic.pause(for: 3600) }
        vc.onOpenSettings = { [weak self] in self?.openSettings() }
        vc.onShowAbout    = { AboutWindowController.show() }
        vc.onUnlock       = { [weak self] in self?.triggerPurchase() }

        let pop = NSPopover()
        pop.behavior              = .transient
        pop.appearance            = NSAppearance(named: .darkAqua)
        pop.contentViewController = vc
        pop.contentSize           = vc.preferredContentSize
        pop.delegate              = self
        menuPopover = pop
        vc.popover  = pop
    }

    // Right-click fallback context menu
    private func buildContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(titled: "Take Break Now",   action: #selector(breakNow),     key: "b", target: self)
        menu.addItem(titled: "Skip Next Break",  action: #selector(skipBreak),    key: "s", target: self)
        menu.addItem(titled: "Pause for 1 Hour", action: #selector(pauseOneHour), key: "p", target: self)
        menu.addItem(.separator())
        menu.addItem(titled: "Settings…",        action: #selector(openSettingsAction), key: ",", target: self)
        menu.addItem(titled: "About IrisBreak",   action: #selector(showAbout),    key: "",  target: self)
        if TrialManager.shared.isTrialExpired {
            menu.addItem(.separator())
            let buy = NSMenuItem(title: "Unlock IrisBreak — $4.99", action: #selector(purchaseAction), keyEquivalent: "")
            buy.target = self; menu.addItem(buy)
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit IrisBreak", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    // MARK: - Callbacks & Settings

    private func wireCallbacks() {
        breakControllerPublic.onStatusUpdate = { [weak self] text in
            DispatchQueue.main.async { self?.updateMenuBarTitle(text) }
        }

        breakControllerPublic.onBreakComplete = { [weak self] in
            DispatchQueue.main.async { self?.rewardBanner.show() }
        }

        breakControllerPublic.onWarning = { [weak self] in
            guard let self else { return }
            self.warningBanner.onSkip  = { self.breakControllerPublic.skipNextBreak() }
            self.warningBanner.onDelay = { self.breakControllerPublic.delay(by: $0) }
            self.warningBanner.show()
        }

        postureController.isBreakActive = { [weak self] in
            self?.breakControllerPublic.isInBreakPublic ?? false
        }
    }

    private func observeSettings() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(eyeBreakSettingsChanged),
            name: .eyeBreakSettingsChanged, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(postureSettingsChangedNote),
            name: .postureSettingsChanged, object: nil)
    }

    @objc private func eyeBreakSettingsChanged()  { breakControllerPublic.applySettings() }
    @objc private func postureSettingsChangedNote() { postureController.restart() }

    // MARK: - Break Actions

    @objc private func breakNow()     { warningBanner.dismiss(); breakControllerPublic.triggerNow() }
    @objc private func skipBreak()    { breakControllerPublic.skipNextBreak() }
    @objc private func pauseOneHour() { breakControllerPublic.pause(for: 3600) }

    // MARK: - Windows

    private func openSettings() {
        if settingsPopover == nil {
            let vc = SettingsViewController()
            settingsVC = vc
            let pop = NSPopover()
            pop.behavior              = .transient
            pop.appearance            = NSAppearance(named: .darkAqua)
            pop.contentViewController = vc
            pop.contentSize           = NSSize(width: 384, height: 630)
            settingsPopover = pop
        }
        guard let button = statusItem.button else { return }
        settingsPopover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc private func openSettingsAction() { openSettings() }
    @objc private func showAbout()          { AboutWindowController.show() }
    @objc private func purchaseAction()     { triggerPurchase() }

    private func triggerPurchase() {
        Task {
            try? await PurchaseManager.shared.purchase()
        }
    }
}

// MARK: - NSPopoverDelegate
extension AppDelegate: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        if let m = outsideClickMonitor { NSEvent.removeMonitor(m); outsideClickMonitor = nil }
    }
}

// MARK: - NSMenu convenience
private extension NSMenu {
    func addItem(titled title: String, action: Selector, key: String, target: AnyObject) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = target
        addItem(item)
    }
}
