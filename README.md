# EyeBreak

A minimal macOS menu bar app that reminds you to follow the **20-20-20 rule** for eye health: every 20 minutes, look at something 20 feet away for 20 seconds.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

---

## What it does

- Runs silently in the menu bar and counts down 20 minutes
- Shows a full-screen overlay on all displays when it's time to rest your eyes
- Auto-dismisses after 20 seconds — no interaction needed
- **Idle detection**: pauses the timer when you step away (≥ 90 s of inactivity) and restarts when you return
- **Call detection**: delays the break if you're on a video/audio call
- Plays soothing music or a simple beep (your choice)
- Skip or pause for 1 hour from the menu bar

---

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel

---

## Build & Run

```bash
git clone https://github.com/YOUR_USERNAME/EyeBreak.git
cd EyeBreak
swift build
open .build/debug/EyeBreak
```

Or open the directory in Xcode via **File → Open** and run from there.

---

## Project structure

```
EyeBreak/
├── Sources/EyeBreak/
│   ├── main.swift                  # Entry point
│   ├── AppDelegate.swift           # Menu bar setup, menu actions
│   ├── BreakController.swift       # Timer, idle detection, break logic
│   ├── OverlayWindowController.swift # Full-screen break overlay
│   ├── AudioPlayer.swift           # Music / beep sound playback
│   ├── CallDetector.swift          # Detects active video/audio calls
│   ├── TrialManager.swift          # 3-day trial state (UserDefaults)
│   └── AboutWindowController.swift # About panel
└── Package.swift
```

---

## Idle detection

If there is no mouse, keyboard, or click activity for **90 seconds**, EyeBreak considers you away and pauses the countdown (menu bar shows `IDLE`). When activity resumes, the 20-minute clock restarts from scratch. Mac sleep/wake is handled the same way.

---

## Trial & Licensing

The app includes a **3-day free trial** tracked via `UserDefaults`. After the trial the app continues to work — a purchase prompt is shown in the menu and About panel. Payment integration (StoreKit / App Store) is not yet wired up.

---

## Author

**Vikas Anand** — [vikasanand.com](https://vikasanand.com) · sakivva@gmail.com

---

## License

MIT
