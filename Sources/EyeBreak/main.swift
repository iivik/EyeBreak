import AppKit

// Must be created before NSApplication.shared is used
let delegate = AppDelegate()
let app = NSApplication.shared
app.delegate = delegate
app.run()
