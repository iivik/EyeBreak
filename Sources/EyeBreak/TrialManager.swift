import Foundation

class TrialManager {
    static let shared = TrialManager()
    private init() { _ = firstLaunchDate }

    private let trialDurationDays = 7
    private let kFirstLaunchKey   = "com.eyebreak.firstLaunchDate"

    var isPurchased: Bool { PurchaseManager.shared.isPurchased }

    var isTrialActive: Bool  { !isPurchased && daysUsed < trialDurationDays }
    var isTrialExpired: Bool { !isPurchased && daysUsed >= trialDurationDays }

    var daysUsed: Int { Int(Date().timeIntervalSince(firstLaunchDate) / 86_400) }
    var daysRemaining: Int { max(0, trialDurationDays - daysUsed) }

    var statusLabel: String {
        if isPurchased   { return "" }
        if isTrialActive { return " · \(daysRemaining)d trial" }
        return " · EXPIRED"
    }

    private var firstLaunchDate: Date {
        if let stored = UserDefaults.standard.object(forKey: kFirstLaunchKey) as? Date {
            return stored
        }
        let now = Date()
        UserDefaults.standard.set(now, forKey: kFirstLaunchKey)
        return now
    }
}
