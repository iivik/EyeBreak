import Foundation

class StatsManager {
    static let shared = StatsManager()
    private init() { checkMidnightReset() }

    private let kTodayCount     = "com.eyebreak.stats.todayCount"
    private let kLastBreakDate  = "com.eyebreak.stats.lastBreakDate"
    private let kStreakDays     = "com.eyebreak.stats.streakDays"
    private let kTodayRestedSec = "com.eyebreak.stats.todayRestedSec"
    private let kDailyCounts    = "com.eyebreak.stats.dailyCounts"   // [String: Int]
    private let kDailySeconds   = "com.eyebreak.stats.dailySeconds"  // [String: Int]

    static let dailyBreakGoal  = 12
    static let dailyRestedGoal = 240  // 12 breaks × 20 sec

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

    private var dailyCounts: [String: Int] {
        get { UserDefaults.standard.dictionary(forKey: kDailyCounts) as? [String: Int] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: kDailyCounts) }
    }

    private var dailySeconds: [String: Int] {
        get { UserDefaults.standard.dictionary(forKey: kDailySeconds) as? [String: Int] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: kDailySeconds) }
    }

    // MARK: - Formatted

    var todayRestFormatted: String { format(seconds: todayRestedSec) }

    private func format(seconds: Int) -> String {
        if seconds >= 3600 {
            let h = seconds / 3600
            let m = (seconds % 3600) / 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        } else if seconds >= 60 {
            return "\(seconds / 60)m \((seconds % 60))s"
        } else {
            return "\(seconds)s"
        }
    }

    // MARK: - Ring Progress (0.0 – 1.0)

    var todayBreaksProgress: Double {
        min(1.0, Double(todayCount) / Double(StatsManager.dailyBreakGoal))
    }

    var todayRestedProgress: Double {
        min(1.0, Double(todayRestedSec) / Double(StatsManager.dailyRestedGoal))
    }

    var weekConsistencyProgress: Double {
        let cal = Calendar.current
        let today = Date()
        var workdays = 0
        var daysWithBreaks = 0

        for offset in 0..<7 {
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let weekday = cal.component(.weekday, from: date)
            guard weekday >= 2 && weekday <= 6 else { continue }  // Mon–Fri
            workdays += 1
            let count = offset == 0 ? todayCount : (dailyCounts[dateKey(for: date)] ?? 0)
            if count > 0 { daysWithBreaks += 1 }
        }

        return workdays > 0 ? Double(daysWithBreaks) / Double(workdays) : 0
    }

    // MARK: - 7-day data (Mon–Fri of current week, ordered Mon→Fri)

    func currentWeekBreaks() -> [(day: String, count: Int)] {
        let cal = Calendar.current
        let today = Date()
        var result: [(String, Int)] = []

        for offset in (0..<7).reversed() {
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let weekday = cal.component(.weekday, from: date)
            guard weekday >= 2 && weekday <= 6 else { continue }
            let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri"]
            let name = dayNames[weekday - 2]
            let count = offset == 0 ? todayCount : (dailyCounts[dateKey(for: date)] ?? 0)
            result.append((name, count))
        }
        return result
    }

    // MARK: - Record

    func recordBreak(durationSec: Int) {
        checkMidnightReset()

        let now = Date()
        let cal = Calendar.current

        if let last = lastBreakDate {
            let days = cal.dateComponents([.day], from: last, to: now).day ?? 0
            if days == 0      { /* same day, streak unchanged */ }
            else if days == 1 { streakDays += 1 }
            else              { streakDays = 1 }
        } else {
            streakDays = 1
        }

        todayCount     += 1
        todayRestedSec += durationSec
        lastBreakDate   = now

        let key = dateKey(for: now)
        var counts = dailyCounts
        counts[key] = (counts[key] ?? 0) + 1
        dailyCounts = counts

        var secs = dailySeconds
        secs[key] = (secs[key] ?? 0) + durationSec
        dailySeconds = secs

        pruneOldHistory()
    }

    // MARK: - Midnight Reset

    func checkMidnightReset() {
        guard let last = lastBreakDate else { return }
        if !Calendar.current.isDateInToday(last) {
            todayCount     = 0
            todayRestedSec = 0
        }
    }

    // MARK: - Private

    private func dateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func pruneOldHistory() {
        let cal = Calendar.current
        guard let cutoff = cal.date(byAdding: .day, value: -30, to: Date()) else { return }
        let cutoffKey = dateKey(for: cutoff)
        dailyCounts  = dailyCounts.filter  { $0.key >= cutoffKey }
        dailySeconds = dailySeconds.filter { $0.key >= cutoffKey }
    }
}
