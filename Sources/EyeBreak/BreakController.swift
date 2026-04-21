import Foundation
import AppKit
import CoreGraphics

class BreakController {
    var onStatusUpdate: ((String) -> Void)?

    private let breakInterval: TimeInterval = 20 * 60
    private let callRetryInterval: TimeInterval = 60
    private let idleThreshold: TimeInterval = 90   // seconds of inactivity → idle
    private let idleCheckInterval: TimeInterval = 5 // how often we poll system idle time

    private var ticker: Timer?
    private var idleTimer: Timer?
    private var secondsUntilBreak: Int = 20 * 60
    private var isPaused = false
    private var skipNext = false
    private var isIdle = false
    private var isInBreak = false  // overlay is currently visible

    var soundMode: SoundMode {
        get { audio.mode }
        set { audio.mode = newValue }
    }

    private let overlay = OverlayWindowController()
    private let callDetector = CallDetector()
    private let audio = AudioPlayer()

    // MARK: - Public

    func start() {
        resetTicker()
        startIdleMonitor()
        observeSleepWake()
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

    // MARK: - Private

    private func resetTicker() {
        ticker?.invalidate()
        secondsUntilBreak = Int(breakInterval)
        isInBreak = false
        isIdle = false

        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(ticker!, forMode: .common)
    }

    private func tick() {
        guard !isPaused, !isIdle else { return }

        secondsUntilBreak -= 1
        let m = secondsUntilBreak / 60
        let s = secondsUntilBreak % 60
        onStatusUpdate?(String(format: "%02d:%02d", m, s))

        if secondsUntilBreak <= 0 {
            ticker?.invalidate()
            handleBreakTime()
        }
    }

    private func handleBreakTime() {
        if skipNext {
            skipNext = false
            resetTicker()
            return
        }

        if callDetector.isOnCall() {
            onStatusUpdate?("CALL…")
            DispatchQueue.main.asyncAfter(deadline: .now() + callRetryInterval) { [weak self] in
                guard let self else { return }
                if self.callDetector.isOnCall() {
                    self.resetTicker()
                } else {
                    self.executeBreak()
                }
            }
            return
        }

        executeBreak()
    }

    private func executeBreak() {
        isInBreak = true
        onStatusUpdate?("REST")
        audio.start()

        overlay.show {
            self.audio.stop()
            self.isInBreak = false
            // Only restart the ticker if we're not idle; if idle, the idle monitor
            // will call resetTicker() when the user returns.
            if !self.isIdle {
                self.resetTicker()
            }
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

        let systemIdle = secondsSinceLastUserEvent()

        if !isIdle && systemIdle >= idleThreshold {
            // User just went idle
            isIdle = true
            ticker?.invalidate()
            if !isInBreak {
                onStatusUpdate?("IDLE")
            }
        } else if isIdle && systemIdle < idleCheckInterval * 2 {
            // User just came back
            isIdle = false
            if !isInBreak {
                resetTicker()
            }
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
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func systemDidWake() {
        guard !isPaused else { return }
        // Treat wake-from-sleep the same as returning from idle — restart fresh
        isIdle = false
        if !isInBreak {
            resetTicker()
        }
    }
}
