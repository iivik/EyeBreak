import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var breakController: BreakController!
    private var postureController: PostureController!
    private var warningBanner: WarningBannerController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        breakController  = BreakController()
        postureController = PostureController()
        warningBanner    = WarningBannerController()

        setupStatusBar()
        wireCallbacks()
        observeSettings()

        breakController.start()
        postureController.start()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let symCfg = NSImage.SymbolConfiguration(pointSize: 14, weight: .light)
            if let img = NSImage(systemSymbolName: "eye", accessibilityDescription: "EyeBreak") {
                button.image = img.withSymbolConfiguration(symCfg)
            }
            button.imagePosition = .imageLeft
            button.title = "  20:00\(TrialManager.shared.statusLabel)"
            button.font  = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        }

        statusItem.menu = buildMenu()
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

        menu.addItem(.separator())
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
        breakController.onStatusUpdate = { [weak self] text in
            DispatchQueue.main.async { self?.updateMenuBarTitle(text) }
        }

        breakController.onWarning = { [weak self] in
            guard let self else { return }
            self.warningBanner.onSkip  = { self.breakController.skipNextBreak() }
            self.warningBanner.onDelay = { self.breakController.delay(by: $0) }
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
        breakController.applySettings()
    }

    @objc private func postureSettingsChangedNote() {
        postureController.restart()
    }

    // MARK: - Break actions

    @objc private func breakNow()     { warningBanner.dismiss(); breakController.triggerNow() }
    @objc private func skipBreak()    { breakController.skipNextBreak() }
    @objc private func pauseOneHour() { breakController.pause(for: 3600) }

    // MARK: - Windows

    @objc private func openSettings() { SettingsWindowController.show() }
    @objc private func showAbout()    { AboutWindowController.show() }

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
