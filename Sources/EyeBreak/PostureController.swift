import Foundation
import AppKit

class PostureController {
    var isBreakActive: (() -> Bool)?

    private var timer: Timer?
    private let overlay = PostureOverlayController()
    private let callDetector = CallDetector()
    private let callRetryInterval: TimeInterval = 60
    private let breakRetryInterval: TimeInterval = 5

    func start() {
        schedule()
        observeSleepWake()
    }

    func restart() {
        timer?.invalidate()
        timer = nil
        guard AppSettings.shared.postureEnabled else { return }
        schedule()
    }

    private func schedule() {
        timer?.invalidate()
        guard AppSettings.shared.postureEnabled else { return }
        timer = Timer.scheduledTimer(withTimeInterval: AppSettings.shared.postureInterval,
                                     repeats: false) { [weak self] _ in
            self?.fire()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func fire() {
        if isBreakActive?() == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + breakRetryInterval) { [weak self] in
                self?.fire()
            }
            return
        }
        if callDetector.isOnCall() {
            // Retry every minute until the call ends, then show the reminder
            DispatchQueue.main.asyncAfter(deadline: .now() + callRetryInterval) { [weak self] in
                guard let self else { return }
                if self.callDetector.isOnCall() {
                    self.schedule()
                } else {
                    self.showOverlay()
                }
            }
            return
        }
        showOverlay()
    }

    private func showOverlay() {
        overlay.show { [weak self] in
            self?.schedule()
        }
    }

    // MARK: - Sleep / Wake

    private func observeSleepWake() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification, object: nil)
    }

    @objc private func systemWillSleep() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func systemDidWake() {
        // Delay restart so the audio system has time to reinitialise after wake
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.schedule()
        }
    }
}
