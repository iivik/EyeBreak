import AVFoundation
import Foundation

// Persisted via UserDefaults
enum SoundMode: String {
    case music = "music"
    case beep  = "beep"
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
        // ── Phrase A — gentle descent from C5
        (523.25, 0.55),   // C5
        (440.00, 0.45),   // A4
        (392.00, 0.45),   // G4
        (440.00, 0.45),   // A4
        (523.25, 0.70),   // C5  (small peak)
        (440.00, 0.45),   // A4
        (392.00, 0.45),   // G4
        (329.63, 0.50),   // E4
        (261.63, 0.90),   // C4  (rest on tonic)
        (0,      0.45),   // rest

        // ── Phrase B — ascending answering phrase
        (261.63, 0.45),   // C4
        (293.66, 0.45),   // D4
        (329.63, 0.45),   // E4
        (392.00, 0.55),   // G4
        (440.00, 0.60),   // A4
        (392.00, 0.45),   // G4
        (329.63, 0.45),   // E4
        (261.63, 1.00),   // C4  (breath)
        (0,      0.40),   // rest

        // ── Phrase C — higher variation
        (329.63, 0.45),   // E4
        (392.00, 0.45),   // G4
        (440.00, 0.50),   // A4
        (523.25, 0.65),   // C5
        (440.00, 0.45),   // A4
        (392.00, 0.45),   // G4
        (329.63, 0.45),   // E4
        (293.66, 0.45),   // D4
        (261.63, 0.85),   // C4
        (0,      0.35),   // rest

        // ── Phrase D — closing cadence, settle to tonic
        (293.66, 0.45),   // D4
        (329.63, 0.45),   // E4
        (392.00, 0.45),   // G4
        (329.63, 0.45),   // E4
        (293.66, 0.45),   // D4
        (261.63, 1.50),   // C4  (final hold — fades out here)
    ]
    // Total melody ≈ 17.7 s; with 2 s silence tail the buffer ≈ 19.7 s,
    // and a 3.5 s global fade-out covers the final hold.

    // MARK: - Public

    func start() {
        stop()
        switch mode {
        case .music: playMusic()
        case .beep:  playBeep()
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
