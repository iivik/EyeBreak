import AppKit
import Darwin

// ── Single-instance enforcement ──────────────────────────────────────────────
// flock() on a /tmp lock file. The OS releases the lock automatically when
// the process exits (crash or clean), so stale locks are never a problem.
private let _lockFD: Int32 = {
    let path = "/tmp/com.eyebreak.lock"
    let fd   = open(path, O_CREAT | O_RDWR, 0o644)
    guard fd >= 0 else { return -1 }
    if flock(fd, LOCK_EX | LOCK_NB) != 0 {
        // Another instance is already running — bring it to focus and quit this one.
        // (NSApp isn't set up yet so we just exit cleanly.)
        fputs("EyeBreak is already running.\n", stderr)
        exit(0)
    }
    return fd   // keep open for the lifetime of the process to hold the lock
}()

_ = _lockFD   // force evaluation before NSApplication starts

// ── App bootstrap ─────────────────────────────────────────────────────────────
let delegate = AppDelegate()
let app      = NSApplication.shared
app.delegate = delegate
app.run()
