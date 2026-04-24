import AVFoundation
import Foundation

// Persisted via UserDefaults
enum SoundMode: String {
    case music  = "music"
    case beep   = "beep"
    case silent = "silent"
}

/// Synthesises all audio in memory — no bundled files required.
///
/// Music mode  — a gentle 20-second pentatonic (C major) melody with a
///               flute-like timbre (ADSR + harmonics + vibrato), global
///               fade-in and fade-out.
///
/// Beep mode   — two soft bell dings: one at break start, one at second 18
///               as a gentle "almost done" cue.
class AudioPlayer {

    var mode: SoundMode = .music

    private var engine: AVAudioEngine?
    private var players: [AVAudioPlayerNode] = []
    private let sampleRate: Double = 44100

    // MARK: - C pentatonic melody  (C4 D4 E4 G4 A4 C5)
    // Each entry: (frequency Hz, duration seconds).  0 Hz = rest.
    private let melody: [(hz: Float, dur: Double)] = [
        // ── Phrase A — gentle arch: rise to E5 then settle
        (329.63, 0.45),   // E4
        (392.00, 0.40),   // G4
        (440.00, 0.40),   // A4
        (493.88, 0.50),   // B4
        (523.25, 0.65),   // C5   peak
        (493.88, 0.40),   // B4
        (440.00, 0.40),   // A4
        (392.00, 0.50),   // G4
        (349.23, 0.45),   // F4   semitone step — distinctly Western
        (329.63, 0.80),   // E4
        (0,      0.35),   // rest

        // ── Phrase B — step-wise descent with F and B
        (523.25, 0.45),   // C5
        (493.88, 0.40),   // B4
        (440.00, 0.40),   // A4
        (392.00, 0.45),   // G4
        (349.23, 0.45),   // F4
        (329.63, 0.40),   // E4
        (293.66, 0.40),   // D4
        (261.63, 0.90),   // C4
        (0,      0.40),   // rest

        // ── Phrase C — lyrical ascending answer
        (261.63, 0.40),   // C4
        (329.63, 0.40),   // E4
        (349.23, 0.45),   // F4
        (392.00, 0.45),   // G4
        (440.00, 0.50),   // A4
        (493.88, 0.55),   // B4
        (523.25, 0.75),   // C5
        (440.00, 0.40),   // A4
        (392.00, 0.45),   // G4
        (329.63, 0.80),   // E4
        (0,      0.30),   // rest

        // ── Phrase D — closing cadence B→C resolution (very Western)
        (349.23, 0.40),   // F4
        (329.63, 0.40),   // E4
        (293.66, 0.45),   // D4
        (261.63, 1.60),   // C4   final hold
    ]
    // Total melody ≈ 17.7 s; with 2 s silence tail the buffer ≈ 19.7 s,
    // and a 3.5 s global fade-out covers the final hold.

    // MARK: - Public

    func start() {
        stop()
        switch mode {
        case .music:  playMusic()
        case .beep:   playBeep()
        case .silent: return
        }
    }

    func stop() {
        players.forEach { $0.stop() }
        players = []
        if engine?.isRunning == true { engine?.stop() }
        engine = nil
    }

    // MARK: - Music

    private func playMusic() {
        let eng = makeEngine()
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = buildMelodyBuffer(format: format) else { return }

        let node = AVAudioPlayerNode()
        eng.attach(node)
        eng.connect(node, to: eng.mainMixerNode, format: format)
        eng.mainMixerNode.outputVolume = 0.82
        node.scheduleBuffer(buffer)
        players = [node]
        launch(eng)
    }

    private func buildMelodyBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let melodyDur = melody.reduce(0.0) { $0 + $1.dur }
        let totalDur  = melodyDur + 2.0          // 2 s silence tail for fade-out
        let frameCount = AVAudioFrameCount(sampleRate * totalDur)

        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let chL = buf.floatChannelData?[0],
              let chR = buf.floatChannelData?[1] else { return nil }
        buf.frameLength = frameCount

        var offset = 0
        for note in melody {
            let nFrames = Int(note.dur * sampleRate)
            guard offset + nFrames <= Int(frameCount) else { break }
            if note.hz > 0 {
                renderNote(hz: note.hz, frames: nFrames,
                           chL: chL, chR: chR, offset: offset)
            }
            // rests and silence tail remain 0.0 (zeroed by Swift)
            offset += nFrames
        }

        // ── Global envelope: 0.6 s fade-in, 3.5 s fade-out
        let total    = Int(frameCount)
        let fadeIn   = Int(sampleRate * 0.6)
        let fadeOut  = Int(sampleRate * 3.5)
        for i in 0..<total {
            let eIn:  Float = i < fadeIn               ? Float(i) / Float(fadeIn)             : 1.0
            let eOut: Float = i > (total - fadeOut)    ? Float(total - i) / Float(fadeOut)    : 1.0
            let e = eIn * max(eOut, 0)
            chL[i] *= e
            chR[i] *= e
        }

        return buf
    }

    /// Renders one note with an ADSR envelope and a warm flute-like timbre.
    private func renderNote(hz: Float, frames: Int,
                            chL: UnsafeMutablePointer<Float>,
                            chR: UnsafeMutablePointer<Float>,
                            offset: Int) {
        let sr = Float(sampleRate)
        let gain: Float = 0.30

        let attackF  = max(1, min(Int(sr * 0.030), frames / 4))   // 30 ms
        let decayF   = max(1, min(Int(sr * 0.055), frames / 4))   // 55 ms
        let releaseF = max(1, min(Int(sr * 0.085), frames / 3))   // 85 ms
        let sustain: Float = 0.74

        for i in 0..<frames {
            let t = Float(i) / sr

            // ── ADSR
            let env: Float
            if i < attackF {
                env = Float(i) / Float(attackF)
            } else if i < attackF + decayF {
                let d = Float(i - attackF) / Float(decayF)
                env = 1.0 - d * (1.0 - sustain)
            } else if i > frames - releaseF {
                env = sustain * Float(frames - i) / Float(releaseF)
            } else {
                env = sustain
            }

            // ── Vibrato: 5 Hz, ±0.35 %, delayed onset after attack
            let onset = Float(max(0, i - attackF * 2)) / (sr * 0.20)
            let vDepth: Float = 0.0035 * min(1.0, onset)
            let vib: Float = 1.0 + vDepth * sin(2.0 * .pi * 5.0 * t)

            // ── Flute harmonics: fundamental + octave (28 %) + 12th (8 %)
            let h1 = sin(2.0 * .pi *       hz * vib * t)
            let h2 = 0.28 * sin(2.0 * .pi * 2 * hz * vib * t)
            let h3 = 0.08 * sin(2.0 * .pi * 3 * hz * vib * t)
            let sample = gain * env * (h1 + h2 + h3) / 1.36   // normalised

            chL[offset + i] = sample
            chR[offset + i] = sample
        }
    }

    // MARK: - Beep

    private func playBeep() {
        let eng = makeEngine()
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else { return }

        // Start bell (A5) at t = 0 s, end cue (E5) at t = 18 s
        let dings: [(startSec: Double, hz: Float)] = [
            (0.0,  880.0),
            (18.0, 659.26),
        ]

        eng.mainMixerNode.outputVolume = 0.72

        for ding in dings {
            guard let buf = buildBellBuffer(format: format,
                                            hz: ding.hz,
                                            startSec: ding.startSec) else { continue }
            let node = AVAudioPlayerNode()
            eng.attach(node)
            eng.connect(node, to: eng.mainMixerNode, format: format)
            node.scheduleBuffer(buf)
            players.append(node)
        }

        launch(eng)
    }

    private func buildBellBuffer(format: AVAudioFormat,
                                  hz: Float,
                                  startSec: Double) -> AVAudioPCMBuffer? {
        let ringDur   = 2.6                          // ring duration
        let totalDur  = startSec + ringDur
        let frameCount = AVAudioFrameCount(sampleRate * totalDur)

        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let chL = buf.floatChannelData?[0],
              let chR = buf.floatChannelData?[1] else { return nil }
        buf.frameLength = frameCount

        let sr       = Float(sampleRate)
        let bellOff  = Int(startSec * sampleRate)
        let bellLen  = Int(ringDur  * sampleRate)

        for i in 0..<Int(frameCount) {
            guard i >= bellOff else { continue }
            let fi = i - bellOff
            guard fi < bellLen else { break }

            let t = Float(fi) / sr

            // Fast 1-ms attack then exponential ring decay
            let attack: Float = fi < Int(sr * 0.001) ? Float(fi) / Float(Int(sr * 0.001)) : 1.0
            let decay = exp(-2.6 * t)

            // Partials: fundamental, octave (fast-decay), slight inharmonic third
            let p1 =       sin(2.0 * .pi * hz        * t)
            let p2 = 0.50 * exp(-1.8 * t) * sin(2.0 * .pi * hz * 2.00 * t)
            let p3 = 0.22 * exp(-3.8 * t) * sin(2.0 * .pi * hz * 3.05 * t)  // slightly inharmonic

            let sample: Float = 0.20 * attack * decay * (p1 + p2 + p3) / 1.72

            chL[i] = sample
            chR[i] = sample
        }

        return buf
    }

    // MARK: - Posture Alert (static func — independent of break audio state)

    /// Sharp ascending two-tone "attention" ping. Distinct from break sounds.
    /// C6 → E6 quick stab, bright marimba-like timbre, 0.9 s total.
    static func playPostureAlert() {
        let sr: Double = 44100
        let eng = AVAudioEngine()
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 2) else { return }

        // Two hits: C6 (1046 Hz) at t=0, E6 (1319 Hz) at t=0.12 s
        let hits: [(startSec: Double, hz: Float)] = [(0.0, 1046.5), (0.12, 1318.5)]
        var nodes: [AVAudioPlayerNode] = []

        for hit in hits {
            let hitLen   = 0.55
            let totalDur = hit.startSec + hitLen
            let frameCount = AVAudioFrameCount(sr * totalDur)
            guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
                  let chL = buf.floatChannelData?[0],
                  let chR = buf.floatChannelData?[1] else { continue }
            buf.frameLength = frameCount

            let hitOff = Int(hit.startSec * sr)
            let hitLen2 = Int(hitLen * sr)
            let fsr = Float(sr)

            for i in 0..<Int(frameCount) {
                guard i >= hitOff else { continue }
                let fi = i - hitOff
                guard fi < hitLen2 else { break }
                let t = Float(fi) / fsr

                // Fast attack (3 ms), sharp exponential decay — marimba character
                let attack: Float = fi < Int(fsr * 0.003) ? Float(fi) / Float(Int(fsr * 0.003)) : 1.0
                let decay = exp(-5.5 * t)

                let hz = hit.hz
                // Marimba partials: fundamental + 4th harmonic (fast decay)
                let p1 = sin(2.0 * .pi * hz        * t)
                let p2 = 0.35 * exp(-12.0 * t) * sin(2.0 * .pi * hz * 4.0 * t)
                let sample: Float = 0.28 * attack * decay * (p1 + p2) / 1.35

                chL[i] = sample; chR[i] = sample
            }

            let node = AVAudioPlayerNode()
            eng.attach(node)
            eng.connect(node, to: eng.mainMixerNode, format: format)
            node.scheduleBuffer(buf)
            nodes.append(node)
        }

        eng.mainMixerNode.outputVolume = 0.85
        do {
            try eng.start()
            nodes.forEach { $0.play() }
        } catch { return }

        // Keep engine alive until sound finishes, then release
        let totalDuration = hits.last.map { $0.startSec + 0.55 } ?? 0.7
        DispatchQueue.global().asyncAfter(deadline: .now() + totalDuration + 0.1) {
            nodes.forEach { $0.stop() }
            eng.stop()
        }
    }

    // MARK: - Helpers

    private func makeEngine() -> AVAudioEngine {
        let eng = AVAudioEngine()
        engine = eng
        players = []
        return eng
    }

    private func launch(_ eng: AVAudioEngine) {
        do {
            try eng.start()
            players.forEach { $0.play() }
        } catch {
            print("[AudioPlayer] engine start failed: \(error.localizedDescription)")
        }
    }
}
