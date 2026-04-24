import Foundation

class StatsManager {
    static let shared = StatsManager()
    private init() { checkMidnightReset() }

    private let kTodayCount      = "com.eyebreak.stats.todayCount"
    private let kLastBreakDate   = "com.eyebreak.stats.lastBreakDate"
    private let kStreakDays      = "com.eyebreak.stats.streakDays"
    private let kTodayRestedSec  = "com.eyebreak.stats.todayRestedSec"

    // MARK: - Accessors

    var todayCount: Int {
        get { UserDefaults.standard.integer(forKey: kTodayCount) }
        set { UserDefaults.standard.set(newValue, forKey: kTodayCount) }
    }

    var streakDays: Int {
        get { UserDefaults.standard.integer(forKey: kStreakDays) }
        set { UserDefaults.standard.set(newValue, forKey: kStreakDays) }
    }

    var todayRestedSec: Int {
        get { UserDefaults.standard.integer(forKey: kTodayRestedSec) }
        set { UserDefaults.standard.set(newValue, forKey: kTodayRestedSec) }
    }

    var lastBreakDate: Date? {
        get { UserDefaults.standard.object(forKey: kLastBreakDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: kLastBreakDate) }
    }

    // MARK: - Formatted

    var todayRestFormatted: String {
        let secs = todayRestedSec
        if secs >= 3600 {
            let h = secs / 3600
            let m = (secs % 3600) / 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        } else if secs >= 60 {
            let m = secs / 60
            return "\(m)m"
        } else {
            return "\(secs)s"
        }
    }

    // MARK: - Record

    func recordBreak(durationSec: Int) {
        checkMidnightReset()

        let now = Date()
        let cal = Calendar.current

        // Update streak
        if let last = lastBreakDate {
            let daysBetween = cal.dateComponents([.day], from: last, to: now).day ?? 0
            if daysBetween == 0 {
                // Same day — streak unchanged (already counted today)
            } else if daysBetween == 1 {
                // Consecutive day — increment streak
                streakDays += 1
            } else {
                // Gap — reset streak to 1
                streakDays = 1
            }
        } else {
            // First break ever
            streakDays = 1
        }

        todayCount      += 1
        todayRestedSec  += durationSec
        lastBreakDate    = now
    }

    // MARK: - Midnight Reset

    func checkMidnightReset() {
        guard let last = lastBreakDate else { return }
        let cal = Calendar.current
        if !cal.isDateInToday(last) {
            // New day — reset today counters
            todayCount     = 0
            todayRestedSec = 0
        }
    }
}
