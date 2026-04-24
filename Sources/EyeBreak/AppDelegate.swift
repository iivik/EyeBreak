import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    var breakControllerPublic: BreakController!   // internal access for SettingsViewController
    private var postureController: PostureController!
    private var warningBanner: WarningBannerController!

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
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.imagePosition = .imageLeft
            // Draw custom eye glyph as template image
            updateStatusBarIcon()
            button.title = "  20m"
            button.font  = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        }

        statusItem.menu = buildMenu()
    }

    private func updateStatusBarIcon() {
        guard let button = statusItem.button else { return }
        let size: CGFloat = 16
        let img = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let color = NSColor.white  // status bar images are template-rendered
            let s = size / 20.0
            ctx.translateBy(x: 0, y: rect.height)
            ctx.scaleBy(x: s, y: -s)

            let path = CGMutablePath()
            path.move(to: CGPoint(x: 1.5, y: 10))
            path.addCurve(to: CGPoint(x: 10, y: 3.5),
                          control1: CGPoint(x: 4, y: 5),
                          control2: CGPoint(x: 7, y: 3.5))
            path.addCurve(to: CGPoint(x: 18.5, y: 10),
                          control1: CGPoint(x: 13, y: 3.5),
                          control2: CGPoint(x: 16, y: 5))
            path.addCurve(to: CGPoint(x: 10, y: 16.5),
                          control1: CGPoint(x: 16, y: 15),
                          control2: CGPoint(x: 13, y: 16.5))
            path.addCurve(to: CGPoint(x: 1.5, y: 10),
                          control1: CGPoint(x: 7, y: 16.5),
                          control2: CGPoint(x: 4, y: 15))
            path.closeSubpath()
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(1.3 / s)
            ctx.addPath(path)
            ctx.strokePath()

            let pupilR: CGFloat = 2.7
            let pupilRect = CGRect(x: 10 - pupilR, y: 10 - pupilR, width: pupilR * 2, height: pupilR * 2)
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: pupilRect)
            return true
        }
        img.isTemplate = true
        button.image = img
    }

    private func updateMenuBarTitle(_ countdown: String) {
        statusItem.button?.title = "  \(countdown)\(TrialManager.shared.statusLabel)"
    }

    // MARK: - Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        menu.addItem(titled: "Take Break Now",   action: #selector(breakNow),     key: "b", target: self)
        menu.addItem(titled: "Skip Next Break",  action: #selector(skipBreak),    key: "s", target: self)
        menu.addItem(titled: "Pause for 1 Hour", action: #selector(pauseOneHour), key: "p", target: self)

        menu.addItem(.separator())
        menu.addItem(titled: "Settings…", action: #selector(openSettings), key: ",", target: self)
        menu.addItem(titled: "About EyeBreak", action: #selector(showAbout), key: "", target: self)

        if TrialManager.shared.isTrialExpired && !TrialManager.shared.isPurchased {
            let buyItem = NSMenuItem(title: "Purchase EyeBreak…",
                                     action: #selector(openPurchase), keyEquivalent: "")
            buyItem.target = self
            menu.addItem(buyItem)
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit EyeBreak",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        return menu
    }

    // MARK: - Callbacks & Settings

    private func wireCallbacks() {
        breakControllerPublic.onStatusUpdate = { [weak self] text in
            DispatchQueue.main.async { self?.updateMenuBarTitle(text) }
        }

        breakControllerPublic.onWarning = { [weak self] in
            guard let self else { return }
            self.warningBanner.onSkip  = { self.breakControllerPublic.skipNextBreak() }
            self.warningBanner.onDelay = { self.breakControllerPublic.delay(by: $0) }
            self.warningBanner.show()
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

    @objc private func eyeBreakSettingsChanged() {
        breakControllerPublic.applySettings()
    }

    @objc private func postureSettingsChangedNote() {
        postureController.restart()
    }

    // MARK: - Break actions

    @objc private func breakNow()     { warningBanner.dismiss(); breakControllerPublic.triggerNow() }
    @objc private func skipBreak()    { breakControllerPublic.skipNextBreak() }
    @objc private func pauseOneHour() { breakControllerPublic.pause(for: 3600) }

    // MARK: - Windows / Popover

    @objc private func openSettings() {
        if settingsPopover == nil {
            let vc = SettingsViewController()
            settingsVC = vc

            let popover = NSPopover()
            popover.behavior            = .transient
            popover.appearance          = NSAppearance(named: .darkAqua)
            popover.contentViewController = vc
            popover.contentSize         = NSSize(width: 384, height: 630)
            settingsPopover = popover
        }

        guard let button = statusItem.button else { return }
        settingsPopover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc private func showAbout() { AboutWindowController.show() }

    @objc private func openPurchase() {
        if let url = URL(string: "https://apps.apple.com") {
            NSWorkspace.shared.open(url)
        }
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
