# EyeBreak

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)

A macOS menu bar app that enforces the **20-20-20 rule** and posture breaks, built on a warm Ember dark design.

---

## What it does

- **20-20-20 break overlay** — full-screen countdown on every connected display, auto-dismisses after 20 s
- **Posture reminders** — separate overlay with an amber arrow rising toward the camera; plays a distinct alert sound
- **1-minute warning banner** — subtle heads-up banner 60 s before each break
- **Idle detection** — pauses the timer after 90 s of inactivity; restarts when you return
- **Call detection** — detects active video/audio calls and defers breaks until the call ends
- **Break + posture sounds** — fully synthesized (no bundled audio files): music mode plays a diatonic C major melody with flute timbre; beep mode plays soft bell dings; posture alert is a sharp marimba double-ping
- **Settings popover** — interval, sound mode, posture frequency, Start at Login, all in the Ember dark UI
- **Stats** — today's completed breaks, current streak, and total rest time tracked in UserDefaults
- **DND / Focus respect** — honors macOS Focus modes via `FocusStatusObserver`
- **Start at Login** — via `SMAppService` (requires bundled .app)
- **System Notifications** — shown at break start when the app is backgrounded (requires bundled .app for `UNUserNotificationCenter` entitlement)
- **3-day trial** with dev bypass (tap version label 5× in About panel to enter a code)

---

## Ember design

All UI uses the **EmberTheme** — a warm dark palette with an amber accent (`#e8a87c`), deep charcoal backgrounds, and muted text tints. Controls (sliders, toggles, segmented pickers) are custom-drawn via `EmberControls` to match the aesthetic consistently across the Settings popover and About panel.

---

## Build & Run

```bash
swift build
.build/debug/EyeBreak &
```

> `UNUserNotificationCenter` and `SMAppService` (Start at Login) require a signed, bundled `.app`. They are silently skipped in the debug binary.

---

## Project structure

```
Sources/EyeBreak/
├── main.swift                    # Entry point — creates AppDelegate, starts run loop
├── AppDelegate.swift             # Menu bar icon, menu actions, break/posture scheduling
├── BreakController.swift         # 20-20-20 timer, idle detection, break sequencing
├── OverlayWindowController.swift # Full-screen 20-second eye-break overlay (all displays)
├── PostureController.swift       # Posture reminder scheduler and state
├── PostureOverlayController.swift# Posture overlay — amber arrow rises via CABasicAnimation
├── WarningBannerController.swift # 1-minute warning banner shown before each break
├── SettingsViewController.swift  # Settings popover (interval, sound, posture, login)
├── EmberTheme.swift              # Color palette and typography constants
├── EmberControls.swift           # Custom NSControl subclasses (slider, toggle, segmented)
├── AudioPlayer.swift             # Synthesized music, beep, and posture alert sounds
├── StatsManager.swift            # Today's breaks, streak, rest-time persistence
├── NotificationManager.swift     # UNUserNotificationCenter wrapper
├── CallDetector.swift            # Detects active video/audio calls via process list
├── TrialManager.swift            # 3-day trial state, dev-bypass unlock code
└── AboutWindowController.swift   # About panel with version, trial status, unlock UI
```

---

## Idle & focus detection

**Idle**: `IOHIDGetParameter` / `CGEventSourceSecondsSinceLastEventType` measures inactivity. After 90 s the countdown pauses and the menu bar icon shows `IDLE`. Any mouse or keyboard event resumes the full 20-minute interval from zero.

**Focus / DND**: `FocusStatusObserver` watches `com.apple.notificationcenter.state` and the `com.apple.donotdisturb` defaults domain. When Focus is active, breaks are deferred until Focus ends.

---

## Trial & Licensing

A **3-day free trial** starts on first launch (timestamp in `UserDefaults`). After expiry the app continues running but shows a purchase prompt in the menu bar and About panel. StoreKit / App Store payment is not yet wired up.

**Dev bypass**: open the About panel and tap the version label **5 times** — an unlock-code field appears. Enter the code to permanently dismiss the trial gate without a payment flow.

---

## Author

**Vikas Anand** — [vikasanand.com](https://vikasanand.com) · sakivva@gmail.com

---

## License

MIT
