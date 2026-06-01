import AppKit

/// Slides in from the top-right after a break completes. Auto-dismisses after 3 seconds.
class BreakRewardBannerController {

    private var panel: NSPanel?

    func show() {
        guard let screen = NSScreen.main else { return }
        panel?.orderOut(nil)
        panel = nil

        let panelW: CGFloat = 300
        let panelH: CGFloat = 60
        let margin: CGFloat = 12
        let menuBarH = NSStatusBar.system.thickness

        let finalX = screen.frame.maxX - panelW - margin
        let finalY = screen.frame.maxY - menuBarH - panelH - margin - 4
        let startY = screen.frame.maxY + panelH

        let p = NSPanel(
            contentRect: NSRect(x: finalX, y: startY, width: panelW, height: panelH),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        p.level              = .floating
        p.backgroundColor    = .clear
        p.isOpaque           = false
        p.hasShadow          = true
        p.collectionBehavior = [.canJoinAllSpaces, .stationary]
        p.contentView?.wantsLayer = true

        buildContent(in: p, panelW: panelW, panelH: panelH)
        p.orderFrontRegardless()
        self.panel = p

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            p.animator().setFrameOrigin(NSPoint(x: finalX, y: finalY))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.dismiss()
        }
    }

    private func dismiss() {
        guard let p = panel else { return }
        let offY = p.frame.origin.y + p.frame.height + 20
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            p.animator().setFrameOrigin(NSPoint(x: p.frame.origin.x, y: offY))
        }, completionHandler: { [weak self] in
            p.orderOut(nil)
            self?.panel = nil
        })
    }

    private func buildContent(in panel: NSPanel, panelW: CGFloat, panelH: CGFloat) {
        guard let root = panel.contentView else { return }

        let bg = NSView()
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.wantsLayer = true
        bg.layer?.backgroundColor = NSColor(calibratedWhite: 0.11, alpha: 0.97).cgColor
        bg.layer?.cornerRadius    = 12
        bg.layer?.borderColor     = NSColor(white: 1, alpha: 0.08).cgColor
        bg.layer?.borderWidth     = 0.5
        bg.layer?.shadowColor     = NSColor.black.cgColor
        bg.layer?.shadowOpacity   = 0.45
        bg.layer?.shadowRadius    = 14
        bg.layer?.shadowOffset    = CGSize(width: 0, height: -4)
        bg.layer?.masksToBounds   = false
        root.addSubview(bg)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: root.topAnchor, constant: 4),
            bg.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 4),
            bg.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -4),
            bg.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -4),
        ])

        let stats = StatsManager.shared

        let check = NSTextField(labelWithString: "✓")
        check.translatesAutoresizingMaskIntoConstraints = false
        check.font      = NSFont.systemFont(ofSize: 15, weight: .semibold)
        check.textColor = ActivityRingsView.middleColor

        let title = NSTextField(labelWithString: "Break complete")
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font      = NSFont.systemFont(ofSize: 13, weight: .semibold)
        title.textColor = NSColor(calibratedWhite: 0.95, alpha: 1)

        var parts = ["\(stats.todayCount) today"]
        if stats.streakDays > 1 { parts.append("🔥 \(stats.streakDays)-day streak") }
        parts.append(stats.todayRestFormatted + " rested")
        let detailStr = parts.joined(separator: "  ·  ")

        let detail = NSTextField(labelWithString: detailStr)
        detail.translatesAutoresizingMaskIntoConstraints = false
        detail.font      = NSFont.systemFont(ofSize: 11, weight: .regular)
        detail.textColor = NSColor(calibratedWhite: 0.55, alpha: 1)

        [check, title, detail].forEach { bg.addSubview($0) }

        NSLayoutConstraint.activate([
            check.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 14),
            check.centerYAnchor.constraint(equalTo: bg.centerYAnchor),

            title.leadingAnchor.constraint(equalTo: check.trailingAnchor, constant: 10),
            title.topAnchor.constraint(equalTo: bg.topAnchor, constant: 11),
            title.trailingAnchor.constraint(lessThanOrEqualTo: bg.trailingAnchor, constant: -12),

            detail.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 3),
            detail.trailingAnchor.constraint(lessThanOrEqualTo: bg.trailingAnchor, constant: -12),
        ])
    }
}
