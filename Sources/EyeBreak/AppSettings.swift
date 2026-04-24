import Foundation

class AppSettings {
    static let shared = AppSettings()
    private init() {}

    private let kBreakInterval   = "com.eyebreak.breakInterval"
    private let kIdleThreshold   = "com.eyebreak.idleThreshold"
    private let kPostureEnabled  = "com.eyebreak.postureEnabled"
    private let kPostureInterval = "com.eyebreak.postureInterval"
    private let kSoundMode       = "com.eyebreak.soundMode"

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
}

extension Notification.Name {
    static let eyeBreakSettingsChanged = Notification.Name("com.eyebreak.settingsChanged")
    static let postureSettingsChanged  = Notification.Name("com.eyebreak.postureSettingsChanged")
}
