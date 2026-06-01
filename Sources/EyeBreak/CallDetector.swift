import AppKit
import CoreAudio
import CoreMediaIO
import CoreGraphics

/// Detects whether the user is on a call, sharing their screen, or presenting.
///
/// Detection signals (any one is enough to block a break):
///   1. Screen sharing active  — Zoom CptHost, macOS session being shared remotely, Screen Sharing viewer
///   2. Presentation active    — AirPlay/display mirroring, or Keynote/PowerPoint running while mirroring
///   3. Camera in use          — CoreMediaIO device query (camera on = video call)
///   4. Microphone in use      — CoreAudio device query (catches audio-only calls)
///
/// Signals 3 & 4 are gated on a known conferencing app (browsers excluded — too many
/// false positives from WebRTC warmup). Presentation detection requires a full-screen
/// window from Keynote/PowerPoint, not just the app running or display mirroring active.
class CallDetector {

    // MARK: - Known conferencing apps

    // Used only for the camera check — browsers removed because mic detection now
    // tracks the orange-dot indicator directly and handles browser calls without gating.
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
        "com.bluejeans.BlueJeans",     // BlueJeans
        "com.ringcentral.RingCentral", // RingCentral
        "com.whereby.Whereby",         // Whereby
    ]

    // MARK: - Public

    /// Returns true when a break should be skipped.
    func isOnCall() -> Bool {
        if isScreenSharingActive() { return true }
        if isPresentationActive()  { return true }

        guard isConferenceAppRunning() else { return false }
        return isMicrophoneBeingUsed() || isCameraBeingUsed()
    }

    // MARK: - Screen sharing

    private func isScreenSharingActive() -> Bool {
        let running = NSWorkspace.shared.runningApplications

        for app in running {
            // Zoom spawns "CptHost" while screen-sharing, even when mic is muted.
            if app.localizedName == "CptHost" { return true }

            // User is viewing another Mac via the built-in Screen Sharing viewer.
            if app.bundleIdentifier == "com.apple.ScreenSharing" { return true }
        }

        // macOS native Screen Sharing: another machine is actively viewing this Mac.
        // CGSSessionScreenIsShared is set in the session dict when screensharingd has a live connection.
        if let dict = CGSessionCopyCurrentDictionary() as? [String: Any] {
            if let val = dict["CGSSessionScreenIsShared"] as? Int, val != 0 { return true }
            if let val = dict["CGSSessionScreenIsShared"] as? Bool, val        { return true }
        }

        return false
    }

    // MARK: - Presentation mode

    private let presentationApps: Set<String> = [
        "com.apple.iWork.Keynote",
        "com.microsoft.Powerpoint",
    ]

    private func isPresentationActive() -> Bool {
        // Only block if a presentation app has a window that fills an entire screen.
        // "Running + mirroring/multiple-screens" was too broad: it triggered when the app
        // was open in edit mode, or when AirPlay mirroring was active for unrelated reasons.
        let presentationPIDs = Set(
            NSWorkspace.shared.runningApplications
                .filter { $0.bundleIdentifier.map { presentationApps.contains($0) } ?? false }
                .map { $0.processIdentifier }
        )
        guard !presentationPIDs.isEmpty else { return false }

        guard let windows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
        ) as? [[String: Any]] else { return false }

        let screenSizes = NSScreen.screens.map { $0.frame.size }

        for win in windows {
            guard let pid = win[kCGWindowOwnerPID as String] as? pid_t,
                  presentationPIDs.contains(pid),
                  let bounds = win[kCGWindowBounds as String] as? [String: Any],
                  let w = bounds["Width"] as? CGFloat,
                  let h = bounds["Height"] as? CGFloat else { continue }
            let winSize = CGSize(width: w, height: h)
            if screenSizes.contains(where: { $0.width == winSize.width && $0.height == winSize.height }) { return true }
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
