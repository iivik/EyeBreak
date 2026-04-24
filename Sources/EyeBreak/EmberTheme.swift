import AppKit

// MARK: - NSColor Hex Extension

extension NSColor {
    convenience init(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex = String(hex.dropFirst()) }
        guard hex.count == 6, let value = UInt64(hex, radix: 16) else {
            self.init(red: 0, green: 0, blue: 0, alpha: 1)
            return
        }
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >>  8) & 0xFF) / 255.0
        let b = CGFloat((value      ) & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - EmberTheme

struct EmberTheme {
    // Surfaces
    let bg:           NSColor
    let bgElev:       NSColor
    let bgSunken:     NSColor
    let border:       NSColor
    let borderStrong: NSColor

    // Text
    let text:         NSColor
    let textMuted:    NSColor
    let textDim:      NSColor

    // Accent
    let accent:       NSColor
    let accentHover:  NSColor
    let accentSoft:   NSColor
    let accentText:   NSColor
    let label:        NSColor

    // Break screen
    let breakAccent:  NSColor
    let breakText:    NSColor
    let breakMeta:    NSColor
    let breakNumber:  NSColor

    // MARK: - Dark Theme

    static let dark = EmberTheme(
        bg:           NSColor(hex: "#1a1613"),
        bgElev:       NSColor(hex: "#221d19"),
        bgSunken:     NSColor(hex: "#15110e"),
        border:       NSColor(red: 1.0,   green: 220/255, blue: 180/255, alpha: 0.08),
        borderStrong: NSColor(red: 1.0,   green: 220/255, blue: 180/255, alpha: 0.14),

        text:         NSColor(hex: "#f4ead9"),
        textMuted:    NSColor(red: 244/255, green: 234/255, blue: 217/255, alpha: 0.62),
        textDim:      NSColor(red: 244/255, green: 234/255, blue: 217/255, alpha: 0.38),

        accent:       NSColor(hex: "#e8a87c"),
        accentHover:  NSColor(hex: "#f0b48a"),
        accentSoft:   NSColor(red: 232/255, green: 168/255, blue: 124/255, alpha: 0.14),
        accentText:   NSColor(hex: "#1a1613"),
        label:        NSColor(hex: "#d9925f"),

        breakAccent:  NSColor(hex: "#f4b88a"),
        breakText:    NSColor(hex: "#f4ead9"),
        breakMeta:    NSColor(red: 244/255, green: 234/255, blue: 217/255, alpha: 0.50),
        breakNumber:  NSColor(red: 244/255, green: 234/255, blue: 217/255, alpha: 0.85)
    )

    // MARK: - Light Theme

    static let light = EmberTheme(
        bg:           NSColor(hex: "#faf7f2"),
        bgElev:       NSColor(hex: "#ffffff"),
        bgSunken:     NSColor(hex: "#f2ede5"),
        border:       NSColor(red: 40/255, green: 20/255, blue: 0/255, alpha: 0.08),
        borderStrong: NSColor(red: 40/255, green: 20/255, blue: 0/255, alpha: 0.14),

        text:         NSColor(hex: "#1f1a16"),
        textMuted:    NSColor(red: 31/255, green: 26/255, blue: 22/255, alpha: 0.62),
        textDim:      NSColor(red: 31/255, green: 26/255, blue: 22/255, alpha: 0.42),

        accent:       NSColor(hex: "#c9722d"),
        accentHover:  NSColor(hex: "#b8611f"),
        accentSoft:   NSColor(red: 201/255, green: 114/255, blue: 45/255, alpha: 0.12),
        accentText:   NSColor(hex: "#ffffff"),
        label:        NSColor(hex: "#a8662f"),

        // Break screen always stays dark
        breakAccent:  NSColor(hex: "#f4b88a"),
        breakText:    NSColor(hex: "#f4ead9"),
        breakMeta:    NSColor(red: 244/255, green: 234/255, blue: 217/255, alpha: 0.50),
        breakNumber:  NSColor(red: 244/255, green: 234/255, blue: 217/255, alpha: 0.85)
    )

    // MARK: - Current (reads NSApp.effectiveAppearance)

    static var current: EmberTheme {
        let name = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        return name == .darkAqua ? .dark : .light
    }
}
