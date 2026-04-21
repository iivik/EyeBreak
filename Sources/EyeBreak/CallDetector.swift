import AppKit
import CoreAudio
import CoreMediaIO

/// Detects whether the user is on a call or sharing their screen.
///
/// Detection signals (any one is enough to block a break):
///   1. Screen sharing active  — Zoom's CptHost helper process, or macOS ScreenSharing app
///   2. Camera in use          — CoreMediaIO device query (camera on = video call)
///   3. Microphone in use      — CoreAudio device query (existing, catches audio-only calls)
///
/// Signals 2 & 3 are gated on a known conferencing app being open to avoid false
/// positives (e.g. a podcast playing in a browser, or FaceTime in the dock but idle).
class CallDetector {

    // MARK: - Known conferencing apps

    private let callApps: Set<String> = [
        "us.zoom.xos",                 // Zoom
        "com.microsoft.teams",         // Microsoft Teams (classic)
        "com.microsoft.teams2",        // Microsoft Teams (new)
        "com.tinyspeck.slackmacgap",   // Slack
        "com.apple.FaceTime",          // FaceTime
        "com.cisco.webex.meetings",    // Cisco Webex
        "com.skype.skype",             // Skype
        "com.discord",                 // Discord
        "com.loom.desktop",            // Loom
        "com.google.Chrome",           // Google Meet / browser calls
        "org.mozilla.firefox",         // Firefox browser calls
        "com.apple.Safari",            // Safari browser calls
        "com.bluejeans.BlueJeans",     // BlueJeans
        "com.ringcentral.RingCentral", // RingCentral
        "com.whereby.Whereby",         // Whereby
    ]

    // MARK: - Public

    /// Returns true when a break should be skipped.
    func isOnCall() -> Bool {
        // Screen sharing is a definitive signal — no need to check anything else.
        if isScreenSharingActive() { return true }

        // For hardware signals, require a known conf app to be open.
        guard isConferenceAppRunning() else { return false }

        // Mic muted but camera on (presenting/watching), or audio-only call with mic live.
        return isMicrophoneBeingUsed() || isCameraBeingUsed()
    }

    // MARK: - Screen sharing

    private func isScreenSharingActive() -> Bool {
        let running = NSWorkspace.shared.runningApplications

        for app in running {
            // Zoom spawns a separate "CptHost" process while screen-sharing.
            // This runs even when the presenter's mic is muted.
            if app.localizedName == "CptHost" { return true }

            // macOS built-in Screen Sharing app
            if app.bundleIdentifier == "com.apple.ScreenSharing" { return true }
        }
        return false
    }

    // MARK: - Conferencing app running

    private func isConferenceAppRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            guard let bid = $0.bundleIdentifier else { return false }
            return callApps.contains(bid)
        }
    }

    // MARK: - Microphone (CoreAudio — read-only, no permission needed)

    private func isMicrophoneBeingUsed() -> Bool {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var getAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )

        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &getAddr, 0, nil, &size, &deviceID
        ) == noErr, deviceID != kAudioDeviceUnknown else { return false }

        var isRunning: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        var runAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(deviceID, &runAddr, 0, nil, &size, &isRunning)
        return isRunning != 0
    }

    // MARK: - Camera (CoreMediaIO — same read-only pattern as CoreAudio, no permission needed)
    //
    // CMIOObjectGetPropertyData signature (7 params, different from CoreAudio's 6):
    //   objectID, address, qualifierSize, qualifier,
    //   dataSize (UInt32 value — capacity),
    //   dataUsed (UInt32* — bytes written out),
    //   data     (void*   — output buffer)
    //
    // Raw FourCharCode values for version-stability:
    //   'dev ' = 0x64657620  kCMIOHardwarePropertyDevices
    //   'rung' = 0x72756E67  kCMIODevicePropertyDeviceIsRunningSomewhere
    //   'glob' = 0x676C6F62  kCMIOObjectPropertyScopeGlobal

    private func isCameraBeingUsed() -> Bool {
        let systemObj = CMIOObjectID(1)
        var listAddr = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(0x64657620),  // 'dev '
            mScope:    CMIOObjectPropertyScope(0x676C6F62),     // 'glob'
            mElement:  CMIOObjectPropertyElement(0)
        )

        // Step 1: how many bytes do we need for the device list?
        var dataSize: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(systemObj, &listAddr, 0, nil, &dataSize) == 0,
              dataSize > 0 else { return false }

        let count = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
        var devices = [CMIODeviceID](repeating: 0, count: count)
        var dataUsed: UInt32 = 0

        // Step 2: fill the device list
        let listStatus = devices.withUnsafeMutableBytes { ptr -> OSStatus in
            guard let base = ptr.baseAddress else { return -1 }
            return CMIOObjectGetPropertyData(
                systemObj, &listAddr,
                0, nil,
                dataSize, &dataUsed,   // capacity (value), then output-bytes pointer
                base                   // void* output buffer
            )
        }
        guard listStatus == 0 else { return false }

        // Step 3: ask each video device whether any process is currently using it
        var runAddr = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(0x72756E67),  // 'rung'
            mScope:    CMIOObjectPropertyScope(0x676C6F62),     // 'glob'
            mElement:  CMIOObjectPropertyElement(0)
        )
        let propSize = UInt32(MemoryLayout<UInt32>.size)

        for deviceID in devices where deviceID != 0 {
            var isRunning: UInt32 = 0
            var used: UInt32 = 0
            let s = withUnsafeMutableBytes(of: &isRunning) { bytes -> OSStatus in
                guard let base = bytes.baseAddress else { return -1 }
                return CMIOObjectGetPropertyData(
                    CMIOObjectID(deviceID), &runAddr,
                    0, nil,
                    propSize, &used,
                    base
                )
            }
            if s == 0 && isRunning != 0 { return true }
        }
        return false
    }
}
