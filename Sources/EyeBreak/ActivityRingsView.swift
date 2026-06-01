import AppKit

/// Three concentric progress rings (Apple Activity Ring style).
/// Outer = weekly consistency, Middle = today's breaks, Inner = eyes rested.
final class ActivityRingsView: NSView {

    // Progress values 0.0 – 1.0
    var outerProgress:  Double = 0 { didSet { animateRing(outerProgress,  layer: outerFill) } }
    var middleProgress: Double = 0 { didSet { animateRing(middleProgress, layer: middleFill) } }
    var innerProgress:  Double = 0 { didSet { animateRing(innerProgress,  layer: innerFill) } }

    // Center label (countdown or dash)
    var centerText: String = "" { didSet { centerLabel.stringValue = centerText } }

    // Ring colors — amber / green / blue matches the three ring meanings
    static let outerColor  = NSColor(hex: "#f4b88a")  // amber: weekly
    static let middleColor = NSColor(hex: "#7ec880")  // green: today's breaks
    static let innerColor  = NSColor(hex: "#7eb8d8")  // blue:  eyes rested

    private let lineWidth: CGFloat = 7
    private let gap:       CGFloat = 5  // gap between ring edges

    private var outerTrack  = CAShapeLayer()
    private var outerFill   = CAShapeLayer()
    private var middleTrack = CAShapeLayer()
    private var middleFill  = CAShapeLayer()
    private var innerTrack  = CAShapeLayer()
    private var innerFill   = CAShapeLayer()

    private let centerLabel: NSTextField = {
        let f = NSTextField(labelWithString: "")
        f.font      = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        f.textColor = NSColor(hex: "#f4b88a")
        f.alignment = .center
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()

    override init(frame: NSRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        wantsLayer = true
        addSubview(centerLabel)
        NSLayoutConstraint.activate([
            centerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override func layout() {
        super.layout()
        guard bounds.width > 1 else { return }
        rebuildRings()
    }

    private func rebuildRings() {
        // Remove old shape layers only
        layer?.sublayers?.filter { $0 is CAShapeLayer }.forEach { $0.removeFromSuperlayer() }

        let cx = bounds.midX
        let cy = bounds.midY

        // Outer radius fills the view minus half-lineWidth padding
        let rOuter  = bounds.width / 2 - lineWidth / 2 - 2
        let rMiddle = rOuter  - lineWidth - gap
        let rInner  = rMiddle - lineWidth - gap

        addRingPair(cx: cx, cy: cy, radius: rOuter,
                    track: outerTrack, fill: outerFill,
                    color: ActivityRingsView.outerColor,
                    currentProgress: outerProgress)
        addRingPair(cx: cx, cy: cy, radius: rMiddle,
                    track: middleTrack, fill: middleFill,
                    color: ActivityRingsView.middleColor,
                    currentProgress: middleProgress)
        addRingPair(cx: cx, cy: cy, radius: rInner,
                    track: innerTrack, fill: innerFill,
                    color: ActivityRingsView.innerColor,
                    currentProgress: innerProgress)
    }

    private func addRingPair(cx: CGFloat, cy: CGFloat, radius: CGFloat,
                             track: CAShapeLayer, fill: CAShapeLayer,
                             color: NSColor, currentProgress: Double) {
        // 12 o'clock start (π/2), sweep CW by full 2π (endAngle = start - 2π).
        // clockwise:true with +2π end = 0-length arc; using -2π forces the full CW sweep.
        let path = CGMutablePath()
        path.addArc(center: CGPoint(x: cx, y: cy), radius: radius,
                    startAngle: .pi / 2, endAngle: .pi / 2 - 2 * .pi, clockwise: true)

        track.path        = path
        track.fillColor   = NSColor.clear.cgColor
        track.strokeColor = color.withAlphaComponent(0.15).cgColor
        track.lineWidth   = lineWidth
        track.lineCap     = .round
        track.strokeEnd   = 1
        layer?.addSublayer(track)

        fill.path         = path
        fill.fillColor    = NSColor.clear.cgColor
        fill.strokeColor  = color.cgColor
        fill.lineWidth    = lineWidth
        fill.lineCap      = .round
        fill.shadowColor  = color.cgColor
        fill.shadowOpacity = 0.5
        fill.shadowRadius  = 3
        fill.shadowOffset  = .zero
        fill.strokeEnd    = CGFloat(currentProgress)
        layer?.addSublayer(fill)
    }

    private func animateRing(_ value: Double, layer: CAShapeLayer) {
        let from = layer.presentation()?.strokeEnd ?? layer.strokeEnd
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = from
        anim.toValue   = CGFloat(value)
        anim.duration  = 0.6
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        anim.isRemovedOnCompletion = false
        anim.fillMode  = .forwards
        layer.strokeEnd = CGFloat(value)
        layer.add(anim, forKey: "strokeEnd")
    }
}
