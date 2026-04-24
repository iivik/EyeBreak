import Foundation
import AppKit

class PostureController {
    private var timer: Timer?
    private let overlay = PostureOverlayController()

    func start() {
        schedule()
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
        overlay.show { [weak self] in
            self?.schedule()
        }
    }
}
