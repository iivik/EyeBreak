import Foundation

class AppSettings {
    static let shared = AppSettings()
    private init() {}

    private let kBreakInterval        = "com.eyebreak.breakInterval"
    private let kIdleThreshold        = "com.eyebreak.idleThreshold"
    private let kPostureEnabled       = "com.eyebreak.postureEnabled"
    private let kPostureInterval      = "com.eyebreak.postureInterval"
    private let kSoundMode            = "com.eyebreak.soundMode"
    private let kBreakEnabled         = "com.eyebreak.breakEnabled"
    private let kBreakDuration        = "com.eyebreak.breakDuration"
    private let kStartAtLogin         = "com.eyebreak.startAtLogin"
    private let kShowInNotifCenter    = "com.eyebreak.showInNotifCenter"
    private let kRespectDnD           = "com.eyebreak.respectDnD"

    var breakInterval: TimeInterval {
        get {
            let v = UserDefaults.standard.double(forKey: kBreakInterval)
            return v >= 20 * 60 ? v : 20 * 60
        }
        set { UserDefaults.standard.set(newValue, forKey: kBreakInterval) }
    }

    var idleThreshold: TimeInterval {
        get {
            let v = UserDefaults.standard.double(forKey: kIdleThreshold)
            return v > 0 ? v : 90
        }
        set { UserDefaults.standard.set(newValue, forKey: kIdleThreshold) }
    }

    var postureEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: kPostureEnabled) != nil else { return true }
            return UserDefaults.standard.bool(forKey: kPostureEnabled)
        }
        set { UserDefaults.standard.set(newValue, forKey: kPostureEnabled) }
    }

    var postureInterval: TimeInterval {
        get {
            let v = UserDefaults.standard.double(forKey: kPostureInterval)
            return v >= 5 * 60 ? v : 10 * 60
        }
        set { UserDefaults.standard.set(newValue, forKey: kPostureInterval) }
    }

    var soundMode: SoundMode {
        get {
            let raw = UserDefaults.standard.string(forKey: kSoundMode) ?? SoundMode.music.rawValue
            return SoundMode(rawValue: raw) ?? .music
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: kSoundMode) }
    }

    var breakEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: kBreakEnabled) != nil else { return true }
            return UserDefaults.standard.bool(forKey: kBreakEnabled)
        }
        set { UserDefaults.standard.set(newValue, forKey: kBreakEnabled) }
    }

    var breakDuration: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: kBreakDuration)
            return v >= 10 ? v : 20
        }
        set { UserDefaults.standard.set(max(10, min(60, newValue)), forKey: kBreakDuration) }
    }

    var startAtLogin: Bool {
        get {
            guard UserDefaults.standard.object(forKey: kStartAtLogin) != nil else { return true }
            return UserDefaults.standard.bool(forKey: kStartAtLogin)
        }
        set { UserDefaults.standard.set(newValue, forKey: kStartAtLogin) }
    }

    var showInNotifCenter: Bool {
        get {
            guard UserDefaults.standard.object(forKey: kShowInNotifCenter) != nil else { return true }
            return UserDefaults.standard.bool(forKey: kShowInNotifCenter)
        }
        set { UserDefaults.standard.set(newValue, forKey: kShowInNotifCenter) }
    }

    var respectDnD: Bool {
        get {
            guard UserDefaults.standard.object(forKey: kRespectDnD) != nil else { return true }
            return UserDefaults.standard.bool(forKey: kRespectDnD)
        }
        set { UserDefaults.standard.set(newValue, forKey: kRespectDnD) }
    }
}

extension Notification.Name {
    static let eyeBreakSettingsChanged = Notification.Name("com.eyebreak.settingsChanged")
    static let postureSettingsChanged  = Notification.Name("com.eyebreak.postureSettingsChanged")
}
