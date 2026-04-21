import Foundation

/// Manages the 3-day free trial.
/// First-launch timestamp is written once to UserDefaults and never changed.
/// For App Store distribution, replace this with StoreKit receipt validation.
class TrialManager {
    static let shared = TrialManager()
    private init() { _ = firstLaunchDate }   // record on first run

    private let trialDurationDays = 3
    private let kFirstLaunchKey   = "com.eyebreak.firstLaunchDate"
    private let kPurchasedKey     = "com.eyebreak.purchased"

    // MARK: - State

    /// True once the user has purchased (set this when StoreKit purchase is confirmed).
    var isPurchased: Bool {
        get { UserDefaults.standard.bool(forKey: kPurchasedKey) }
        set { UserDefaults.standard.set(newValue, forKey: kPurchasedKey) }
    }

    var isTrialActive: Bool {
        return !isPurchased && daysUsed < trialDurationDays
    }

    var isTrialExpired: Bool {
        return !isPurchased && daysUsed >= trialDurationDays
    }

    /// Days elapsed since first launch (0 on day 1).
    var daysUsed: Int {
        let elapsed = Date().timeIntervalSince(firstLaunchDate)
        return Int(elapsed / 86_400)
    }

    var daysRemaining: Int {
        return max(0, trialDurationDays - daysUsed)
    }

    /// Human-readable status for the menu bar.
    var statusLabel: String {
        if isPurchased      { return "" }           // no badge needed
        if isTrialActive    { return " · \(daysRemaining)d trial" }
        return " · EXPIRED"
    }

    // MARK: - Private

    private var firstLaunchDate: Date {
        if let stored = UserDefaults.standard.object(forKey: kFirstLaunchKey) as? Date {
            return stored
        }
        let now = Date()
        UserDefaults.standard.set(now, forKey: kFirstLaunchKey)
        return now
    }
}
