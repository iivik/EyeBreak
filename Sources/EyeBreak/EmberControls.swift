import AppKit

// MARK: - EmberToggle

enum ToggleSize { case md, sm }

class EmberToggle: NSControl {
    var isOn: Bool { didSet { animateToState() } }
    var onChange: ((Bool) -> Void)?

    private let size: ToggleSize
    private var trackLayer  = CALayer()
    private var knobLayer   = CALayer()

    private var trackW: CGFloat { size == .md ? 36 : 30 }
    private var trackH: CGFloat { size == .md ? 22 : 18 }
    private var knobD:  CGFloat { trackH - 4 }

    init(size: ToggleSize = .md, isOn: Bool = false) {
        self.size  = size
        self.isOn  = isOn
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        setupLayers()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    override var intrinsicContentSize: NSSize {
        NSSize(width: trackW, height: trackH)
    }

    private func setupLayers() {
        guard let root = layer else { return }

        // Track
        trackLayer.frame        = CGRect(x: 0, y: 0, width: trackW, height: trackH)
        trackLayer.cornerRadius = trackH / 2
        trackLayer.backgroundColor = isOn
            ? EmberTheme.dark.accent.cgColor
            : NSColor(red: 1, green: 1, blue: 1, alpha: 0.09).cgColor
        root.addSublayer(trackLayer)

        // Knob
        let x: CGFloat = isOn ? trackW - knobD - 2 : 2
        knobLayer.frame        = CGRect(x: x, y: 2, width: knobD, height: knobD)
        knobLayer.cornerRadius = knobD / 2
        knobLayer.backgroundColor = NSColor.white.cgColor
        knobLayer.shadowColor   = NSColor.black.cgColor
        knobLayer.shadowOpacity = 0.35
        knobLayer.shadowRadius  = 2
        knobLayer.shadowOffset  = CGSize(width: 0, height: -1)
        root.addSublayer(knobLayer)
    }

    // MARK: - Animation

    private func animateToState() {
        let theme   = EmberTheme.dark
        let onColor  = theme.accent.cgColor
        let offColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.09).cgColor
        let targetX: CGFloat = isOn ? trackW - knobD - 2 : 2

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.18)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.3, 0.7, 0.3, 1))

        let posAnim                   = CABasicAnimation(keyPath: "position.x")
        posAnim.fromValue             = knobLayer.presentation()?.position.x ?? knobLayer.position.x
        posAnim.toValue               = targetX + knobD / 2
        posAnim.duration              = 0.18
        posAnim.timingFunction        = CAMediaTimingFunction(controlPoints: 0.3, 0.7, 0.3, 1)
        knobLayer.add(posAnim, forKey: "move")

        let bgAnim                    = CABasicAnimation(keyPath: "backgroundColor")
        bgAnim.fromValue              = trackLayer.presentation()?.backgroundColor ?? trackLayer.backgroundColor
        bgAnim.toValue                = isOn ? onColor : offColor
        bgAnim.duration               = 0.18
        trackLayer.add(bgAnim, forKey: "color")

        knobLayer.frame = CGRect(x: targetX, y: 2, width: knobD, height: knobD)
        trackLayer.backgroundColor = isOn ? onColor : offColor

        CATransaction.commit()
    }

    // MARK: - Mouse

    override func mouseDown(with event: NSEvent) {
        isOn = !isOn
        onChange?(isOn)
        sendAction(action, to: target)
    }
}

// MARK: - EmberSlider

class EmberSlider: NSControl {
    var value:    Double { didSet { needsDisplay = true } }
    var minValue: Double
    var maxValue: Double
    var step:     Double
    var onChange: ((Double) -> Void)?

    override var intrinsicContentSize: NSSize { NSSize(width: 160, height: 18) }

    init(value: Double = 0, minValue: Double = 0, maxValue: Double = 1, step: Double = 1) {
        self.value    = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.step     = step
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let theme    = EmberTheme.dark
        let b        = bounds
        let trackH:  CGFloat = 4
        let trackY   = b.midY - trackH / 2
        let knobR:   CGFloat = 7
        let leftPad  = knobR
        let rightPad = knobR
        let trackW   = b.width - leftPad - rightPad
        let pct      = (value - minValue) / (maxValue - minValue)
        let knobX    = leftPad + CGFloat(pct) * trackW

        // Track background
        let bgPath = NSBezierPath(roundedRect: CGRect(x: leftPad, y: trackY, width: trackW, height: trackH), xRadius: 2, yRadius: 2)
        NSColor(red: 1, green: 1, blue: 1, alpha: 0.06).setFill()
        bgPath.fill()
        // Track border
        theme.border.setStroke()
        bgPath.lineWidth = 0.5
        bgPath.stroke()

        // Fill from left to knob
        if pct > 0 {
            let fillW = max(0, knobX - leftPad)
            let fillPath = NSBezierPath(roundedRect: CGRect(x: leftPad, y: trackY, width: fillW, height: trackH), xRadius: 2, yRadius: 2)
            theme.accent.setFill()
            fillPath.fill()
        }

        // Knob with shadow via CoreGraphics
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -1), blur: 3,
                      color: NSColor(red: 0, green: 0, blue: 0, alpha: 0.4).cgColor)
        let knobRect = CGRect(x: knobX - knobR, y: b.midY - knobR, width: knobR * 2, height: knobR * 2)
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fillEllipse(in: knobRect)
        ctx.restoreGState()
    }

    // MARK: - Mouse

    override func mouseDown(with event: NSEvent) {
        setValueFromEvent(event)
        window?.trackEvents(matching: [.leftMouseDragged, .leftMouseUp], timeout: .infinity, mode: .eventTracking) { evt, stop in
            guard let evt else { stop.pointee = true; return }
            if evt.type == .leftMouseUp { stop.pointee = true; return }
            self.setValueFromEvent(evt)
        }
    }

    private func setValueFromEvent(_ event: NSEvent) {
        let loc   = convert(event.locationInWindow, from: nil)
        let knobR: CGFloat = 7
        let leftPad = knobR
        let rightPad = knobR
        let trackW = bounds.width - leftPad - rightPad
        let raw    = Double((loc.x - leftPad) / trackW) * (maxValue - minValue) + minValue
        let stepped = (raw / step).rounded() * step
        value = max(minValue, min(maxValue, stepped))
        onChange?(value)
        sendAction(action, to: target)
    }
}

// MARK: - EmberSegmented

class EmberSegmented: NSControl {
    struct Option {
        let value: String
        let label: String
    }

    var options:    [Option]
    var selected:   String { didSet { needsDisplay = true } }
    var onSelect:   ((String) -> Void)?

    init(options: [Option], selected: String) {
        self.options  = options
        self.selected = selected
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        let n    = CGFloat(options.count)
        let segW: CGFloat = 64
        return NSSize(width: n * segW + 4, height: 26)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let theme = EmberTheme.dark
        let b     = bounds

        // Container
        let container = NSBezierPath(roundedRect: b, xRadius: 7, yRadius: 7)
        NSColor(red: 1, green: 1, blue: 1, alpha: 0.04).setFill()
        container.fill()
        theme.border.setStroke()
        container.lineWidth = 0.5
        container.stroke()

        guard !options.isEmpty else { return }
        let n       = CGFloat(options.count)
        let segW    = (b.width - 4) / n
        let vPad:   CGFloat = 2
        let hPad:   CGFloat = 2

        for (i, opt) in options.enumerated() {
            let segX = hPad + CGFloat(i) * segW
            let segRect = CGRect(x: segX, y: vPad, width: segW, height: b.height - vPad * 2)
            let active  = opt.value == selected

            if active {
                let activePath = NSBezierPath(roundedRect: segRect, xRadius: 5, yRadius: 5)
                theme.accent.setFill()
                activePath.fill()
            }

            let textColor = active ? theme.accentText : theme.text
            let fontSize:  CGFloat = 12
            let font       = NSFont.systemFont(ofSize: fontSize, weight: .medium)
            let attrs: [NSAttributedString.Key: Any] = [
                .font:            font,
                .foregroundColor: textColor,
            ]
            let str   = opt.label as NSString
            let strSz = str.size(withAttributes: attrs)
            let tx    = segRect.midX - strSz.width  / 2
            let ty    = segRect.midY - strSz.height / 2
            str.draw(at: CGPoint(x: tx, y: ty), withAttributes: attrs)
        }
    }

    override func mouseDown(with event: NSEvent) {
        let loc  = convert(event.locationInWindow, from: nil)
        let b    = bounds
        guard !options.isEmpty else { return }
        let n    = CGFloat(options.count)
        let segW = (b.width - 4) / n
        let idx  = Int((loc.x - 2) / segW)
        guard idx >= 0, idx < options.count else { return }
        selected = options[idx].value
        onSelect?(selected)
        sendAction(action, to: target)
    }
}

// MARK: - EyeGlyphView

class EyeGlyphView: NSView {
    var color:     NSColor
    var glyphSize: CGFloat

    init(glyphSize: CGFloat, color: NSColor) {
        self.glyphSize = glyphSize
        self.color     = color
        super.init(frame: NSRect(x: 0, y: 0, width: glyphSize, height: glyphSize))
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { NSSize(width: glyphSize, height: glyphSize) }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let s: CGFloat = glyphSize / 20.0

        // Flip y-axis: AppKit origin is bottom-left, SVG is top-left
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.scaleBy(x: s, y: -s)

        // Eye outline: M1.5,10 C4,5 7,3.5 10,3.5 C13,3.5 16,5 18.5,10 C16,15 13,16.5 10,16.5 C7,16.5 4,15 1.5,10 Z
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 1.5, y: 10))
        path.addCurve(to: CGPoint(x: 10, y: 3.5),
                      control1: CGPoint(x: 4, y: 5),
                      control2: CGPoint(x: 7, y: 3.5))
        path.addCurve(to: CGPoint(x: 18.5, y: 10),
                      control1: CGPoint(x: 13, y: 3.5),
                      control2: CGPoint(x: 16, y: 5))
        path.addCurve(to: CGPoint(x: 10, y: 16.5),
                      control1: CGPoint(x: 16, y: 15),
                      control2: CGPoint(x: 13, y: 16.5))
        path.addCurve(to: CGPoint(x: 1.5, y: 10),
                      control1: CGPoint(x: 7, y: 16.5),
                      control2: CGPoint(x: 4, y: 15))
        path.closeSubpath()

        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(1.3 / s)
        ctx.addPath(path)
        ctx.strokePath()

        // Pupil
        let pupilR: CGFloat = 2.7
        let pupilRect = CGRect(x: 10 - pupilR, y: 10 - pupilR, width: pupilR * 2, height: pupilR * 2)
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: pupilRect)
    }
}
