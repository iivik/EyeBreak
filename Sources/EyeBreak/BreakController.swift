import Foundation
import AppKit
import CoreGraphics

class BreakController {
    var onStatusUpdate: ((String) -> Void)?
    var onWarning: (() -> Void)?           // fires at T-60 seconds

    private let callRetryInterval: TimeInterval = 60
    private let idleCheckInterval: TimeInterval = 5

    private var ticker: Timer?
    private var idleTimer: Timer?
    private var secondsUntilBreak: Int = 0
    private var isPaused   = false
    private var skipNext   = false
    private var isIdle     = false
    private var isInBreak  = false
    private var warnFired  = false         // so we fire the warning only once per cycle

    private let overlay      = OverlayWindowController()
    private let callDetector = CallDetector()
    private let audio        = AudioPlayer()

    // MARK: - Public Accessors (for status pill)

    var secondsUntilBreakPublic: Int { secondsUntilBreak }
    var isPausedPublic: Bool         { isPaused }

    // MARK: - Public

    func start() {
        resetTicker()
        startIdleMonitor()
        observeSleepWake()
    }

    func applySettings() {
        guard !isPaused, !isInBreak else { return }
        resetTicker()
    }

    func skipNextBreak() {
        skipNext = true
        onStatusUpdate?("SKIP")
    }

    func pause(for seconds: TimeInterval) {
        isPaused = true
        ticker?.invalidate()
        onStatusUpdate?("PAUSED")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            guard let self else { return }
            self.isPaused = false
            self.resetTicker()
        }
    }

    func triggerNow() {
        ticker?.invalidate()
        executeBreak()
    }

    func delay(by seconds: TimeInterval) {
        secondsUntilBreak += Int(seconds)
    }

    // MARK: - Private

    private func resetTicker() {
        ticker?.invalidate()
        secondsUntilBreak = Int(AppSettings.shared.breakInterval)
        isInBreak = false
        isIdle    = false
        warnFired = false

        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(ticker!, forMode: .common)
    }

    private func tick() {
        guard !isPaused, !isIdle else { return }

        secondsUntilBreak -= 1

        if secondsUntilBreak == 60 && !warnFired {
            warnFired = true
            onWarning?()
            NotificationManager.shared.postBreakWarning()
        }

        // Format: "Xm" when >60s, "Xs" when ≤60s
        let statusText: String
        if secondsUntilBreak > 60 {
            statusText = "\(secondsUntilBreak / 60)m"
        } else {
            statusText = "\(secondsUntilBreak)s"
        }
        onStatusUpdate?(statusText)

        if secondsUntilBreak <= 0 {
            ticker?.invalidate()
            // If breaks are disabled, just reset without triggering overlay
            guard AppSettings.shared.breakEnabled else {
                resetTicker()
                return
            }
            handleBreakTime()
        }
    }

    private func handleBreakTime() {
        NotificationManager.shared.cancelBreakWarning()

        if skipNext {
            skipNext = false
            resetTicker()
            return
        }

        // Respect Do Not Disturb / Focus mode
        if AppSettings.shared.respectDnD && NotificationManager.shared.isDNDActive() {
            onStatusUpdate?("DND…")
            DispatchQueue.main.asyncAfter(deadline: .now() + callRetryInterval) { [weak self] in
                guard let self else { return }
                // Re-check after 1 min — if still in DND, reset the full timer
                if AppSettings.shared.respectDnD && NotificationManager.shared.isDNDActive() {
                    self.resetTicker()
                } else {
                    self.executeBreak()
                }
            }
            return
        }

        if callDetector.isOnCall() {
            onStatusUpdate?("CALL…")
            DispatchQueue.main.asyncAfter(deadline: .now() + callRetryInterval) { [weak self] in
                guard let self else { return }
                if self.callDetector.isOnCall() { self.resetTicker() } else { self.executeBreak() }
            }
            return
        }

        executeBreak()
    }

    private func executeBreak() {
        isInBreak = true
        onStatusUpdate?("REST")
        audio.mode = AppSettings.shared.soundMode
        audio.start()

        let dur = AppSettings.shared.breakDuration
        overlay.show(duration: dur) {
            StatsManager.shared.recordBreak(durationSec: dur)
            self.audio.stop()
            self.isInBreak = false
            if !self.isIdle { self.resetTicker() }
        }
    }

    // MARK: - Idle Detection

    private func startIdleMonitor() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleCheckInterval, repeats: true) { [weak self] _ in
            self?.checkIdle()
        }
        RunLoop.main.add(idleTimer!, forMode: .common)
    }

    private func checkIdle() {
        guard !isPaused else { return }

        let sysIdle = secondsSinceLastUserEvent()
        let threshold = AppSettings.shared.idleThreshold

        if !isIdle && sysIdle >= threshold {
            isIdle = true
            ticker?.invalidate()
            if !isInBreak { onStatusUpdate?("IDLE") }

        } else if isIdle && sysIdle < idleCheckInterval * 2 {
            isIdle = false
            if !isInBreak { resetTicker() }
        }
    }

    private func secondsSinceLastUserEvent() -> TimeInterval {
        let mouse = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        let key   = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        let click = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .leftMouseDown)
        return min(mouse, min(key, click))
    }

    // MARK: - Sleep / Wake

    private func observeSleepWake() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification, object: nil)
    }

    @objc private func systemDidWake() {
        guard !isPaused else { return }
        isIdle = false
        if !isInBreak { resetTicker() }
    }
}
