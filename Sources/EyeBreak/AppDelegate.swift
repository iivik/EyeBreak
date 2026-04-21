import AppKit

private let kSoundModeKey = "com.eyebreak.soundMode"

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var breakController: BreakController!
    private var musicMenuItem: NSMenuItem!
    private var beepMenuItem:  NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        breakController = BreakController()

        let saved = UserDefaults.standard.string(forKey: kSoundModeKey) ?? SoundMode.music.rawValue
        breakController.soundMode = SoundMode(rawValue: saved) ?? .music

        setupStatusBar()

        breakController.onStatusUpdate = { [weak self] text in
            DispatchQueue.main.async { self?.updateMenuBarTitle(text) }
        }
        breakController.start()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // SF Symbol eye — clean, scalable, no emoji
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

        // ── Sound submenu
        let soundParent = NSMenuItem(title: "Sound", action: nil, keyEquivalent: "")
        let soundSub    = NSMenu(title: "Sound")

        musicMenuItem = NSMenuItem(title: "Soothing Music", action: #selector(selectMusic), keyEquivalent: "")
        musicMenuItem.target = self
        beepMenuItem  = NSMenuItem(title: "Beep Only",      action: #selector(selectBeep),  keyEquivalent: "")
        beepMenuItem.target  = self

        soundSub.addItem(musicMenuItem)
        soundSub.addItem(beepMenuItem)
        soundParent.submenu = soundSub
        menu.addItem(soundParent)
        updateSoundCheckmarks()

        menu.addItem(.separator())

        // ── About / purchase
        menu.addItem(titled: "About EyeBreak", action: #selector(showAbout), key: "", target: self)

        if TrialManager.shared.isTrialExpired && !TrialManager.shared.isPurchased {
            let buyItem = NSMenuItem(title: "Purchase EyeBreak…", action: #selector(openPurchase), keyEquivalent: "")
            buyItem.target = self
            menu.addItem(buyItem)
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit EyeBreak", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        return menu
    }

    // MARK: - Sound

    @objc private func selectMusic() { applySound(.music) }
    @objc private func selectBeep()  { applySound(.beep)  }

    private func applySound(_ mode: SoundMode) {
        breakController.soundMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: kSoundModeKey)
        updateSoundCheckmarks()
    }

    private func updateSoundCheckmarks() {
        let current = breakController.soundMode
        musicMenuItem.state = (current == .music) ? .on : .off
        beepMenuItem.state  = (current == .beep)  ? .on : .off
    }

    // MARK: - Break actions

    @objc private func breakNow()     { breakController.triggerNow() }
    @objc private func skipBreak()    { breakController.skipNextBreak() }
    @objc private func pauseOneHour() { breakController.pause(for: 3600) }

    // MARK: - About / Purchase

    @objc private func showAbout() {
        AboutWindowController.show()
    }

    @objc private func openPurchase() {
        // Replace this URL with your Mac App Store link once published
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
