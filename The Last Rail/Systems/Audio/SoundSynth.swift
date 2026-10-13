import Foundation

/// Offline synthesis of every sound in the game. No audio files are required.
/// All functions are pure and can run off the main actor.
nonisolated enum SoundSynth {
    static let sampleRate: Double = 22050

    struct Noise {
        var state: UInt32 = 0x12345678
        mutating func next() -> Float {
            state ^= state << 13; state ^= state >> 17; state ^= state << 5
            return Float(Int32(bitPattern: state)) / Float(Int32.max)
        }
    }

    private static func buffer(_ seconds: Double) -> [Float] {
        [Float](repeating: 0, count: Int(seconds * sampleRate))
    }

    private static func env(_ i: Int, _ n: Int, attack: Double, release: Double) -> Float {
        let t = Double(i) / sampleRate
        let total = Double(n) / sampleRate
        if t < attack { return Float(t / max(attack, 0.0001)) }
        if t > total - release { return Float(max(0, (total - t) / max(release, 0.0001))) }
        return 1
    }

    static func tone(_ freq: Double, _ seconds: Double, volume: Float = 0.4, attack: Double = 0.005, release: Double = 0.08,
                     square: Bool = false, slide: Double = 0) -> [Float] {
        var out = buffer(seconds)
        var phase = 0.0
        for i in 0..<out.count {
            let f = freq + slide * Double(i) / Double(out.count)
            phase += f / sampleRate
            let s = square ? (phase.truncatingRemainder(dividingBy: 1) < 0.5 ? 1.0 : -1.0) * 0.5 : sin(2 * .pi * phase)
            out[i] = Float(s) * volume * env(i, out.count, attack: attack, release: release)
        }
        return out
    }

    static func noise(_ seconds: Double, volume: Float, lowpass: Float = 0.2, attack: Double = 0.002, release: Double = 0.05, seed: UInt32 = 1) -> [Float] {
        var out = buffer(seconds)
        var n = Noise(state: seed | 1)
        var lp: Float = 0
        for i in 0..<out.count {
            lp += lowpass * (n.next() - lp)
            out[i] = lp * volume * env(i, out.count, attack: attack, release: release)
        }
        return out
    }

    static func concat(_ parts: [[Float]]) -> [Float] { parts.flatMap { $0 } }

    static func mix(_ a: [Float], _ b: [Float], offset: Int = 0) -> [Float] {
        var out = a
        if out.count < b.count + offset { out += [Float](repeating: 0, count: b.count + offset - out.count) }
        for i in 0..<b.count { out[i + offset] += b[i] }
        return out
    }

    // MARK: Effects

    static func effect(_ e: SoundEffect) -> [Float] {
        switch e {
        case .footstep:
            return noise(0.06, volume: 0.35, lowpass: 0.12, release: 0.04, seed: 7)
        case .pickup:
            return concat([tone(660, 0.06, volume: 0.25, square: true), tone(990, 0.09, volume: 0.25, square: true)])
        case .menuSelect:
            return tone(880, 0.05, volume: 0.18, square: true, slide: 220)
        case .menuMove:
            return tone(520, 0.03, volume: 0.12, square: true)
        case .craft:
            return concat([tone(523, 0.08, volume: 0.25, square: true), tone(659, 0.08, volume: 0.25, square: true),
                           tone(784, 0.08, volume: 0.25, square: true), tone(1046, 0.22, volume: 0.25, release: 0.15, square: true)])
        case .engineStart:
            var out = noise(1.6, volume: 0.5, lowpass: 0.05, attack: 0.3, release: 0.4, seed: 3)
            for i in 0..<out.count {
                let t = Double(i) / sampleRate
                let rate = 3 + t * 6
                out[i] *= Float(0.55 + 0.45 * sin(2 * .pi * rate * t))
            }
            return mix(out, tone(55, 1.6, volume: 0.2, attack: 0.4, release: 0.5, slide: 30))
        case .arrival:
            let bell = mix(tone(988, 0.9, volume: 0.18, release: 0.8), tone(1976, 0.6, volume: 0.06, release: 0.5))
            return mix(noise(0.7, volume: 0.25, lowpass: 0.6, attack: 0.05, release: 0.5, seed: 9), bell, offset: Int(0.3 * sampleRate))
        case .secret:
            return concat([523, 659, 784, 988, 1318].map { tone($0, 0.09, volume: 0.18, release: 0.06) } + [tone(1568, 0.4, volume: 0.15, release: 0.35)])
        case .damage:
            return mix(tone(110, 0.15, volume: 0.4, slide: -60), noise(0.12, volume: 0.3, lowpass: 0.3, seed: 11))
        case .radio:
            var out = noise(1.0, volume: 0.25, lowpass: 0.7, attack: 0.05, release: 0.2, seed: 13)
            for i in 0..<out.count { out[i] *= Float(0.6 + 0.4 * sin(Double(i) / 300)) }
            return out
        case .door:
            return mix(tone(140, 0.25, volume: 0.2, square: true, slide: -40), noise(0.2, volume: 0.25, lowpass: 0.25, seed: 17))
        case .error:
            return concat([tone(196, 0.08, volume: 0.2, square: true), tone(147, 0.12, volume: 0.2, square: true)])
        case .paper:
            return noise(0.15, volume: 0.2, lowpass: 0.8, attack: 0.02, release: 0.1, seed: 19)
        case .departure:
            // Two-tone horn.
            return mix(tone(311, 0.9, volume: 0.18, attack: 0.05, release: 0.2, square: true), tone(392, 0.9, volume: 0.14, attack: 0.05, release: 0.2, square: true))
        case .refuel:
            var out = noise(0.6, volume: 0.25, lowpass: 0.15, attack: 0.05, release: 0.2, seed: 23)
            for i in 0..<out.count { out[i] *= Float(0.5 + 0.5 * sin(Double(i) / 120)) }
            return out
        case .faint:
            return concat([tone(392, 0.2, volume: 0.2), tone(330, 0.2, volume: 0.2), tone(262, 0.5, volume: 0.2, release: 0.4)])
        }
    }

    // MARK: Loops

    /// Diesel rumble with rhythmic rail clacks. Seamless 2 s loop.
    static func trainLoop() -> [Float] {
        let seconds = 2.0
        var out = buffer(seconds)
        var n = Noise(state: 99)
        var lp: Float = 0
        for i in 0..<out.count {
            lp += 0.04 * (n.next() - lp)
            let t = Double(i) / sampleRate
            let rumble = Float(sin(2 * .pi * 48 * t)) * 0.12 + lp * 0.5
            out[i] = rumble
        }
        // Clack-clack, twice per loop.
        for start in [0.0, 0.18, 1.0, 1.18] {
            let clack = noise(0.05, volume: 0.5, lowpass: 0.5, release: 0.04, seed: UInt32(start * 1000) + 5)
            out = mix(out, clack, offset: Int(start * sampleRate))
        }
        return Array(out.prefix(Int(seconds * sampleRate)))
    }

    /// Ambience per region, ~8 s seamless loop (wind + region details).
    static func ambience(_ region: Region) -> [Float] {
        let seconds = 8.0
        var out = buffer(seconds)
        var n = Noise(state: UInt32(region.rawValue.count * 77 + 3))
        var lp: Float = 0
        let windStrength: Float = region == .mountain ? 0.45 : (region == .forest ? 0.22 : 0.18)
        for i in 0..<out.count {
            lp += 0.015 * (n.next() - lp)
            let t = Double(i) / Double(out.count)
            let swell = Float(0.6 + 0.4 * sin(2 * .pi * t) * sin(2 * .pi * 2 * t + 1))
            out[i] = lp * windStrength * swell * 3
        }
        var rng = SeededRandom(seed: UInt64(region.rawValue.count))
        switch region {
        case .forest:
            for _ in 0..<5 {
                let start = Double(rng.int(0...70)) / 10
                let base = Double(rng.int(2200...3200))
                let chirp = concat([tone(base, 0.05, volume: 0.05, slide: 600), tone(base + 300, 0.06, volume: 0.04, slide: -400)])
                out = mix(out, chirp, offset: Int(start * sampleRate))
            }
            // Rain hiss
            out = mix(out, noise(seconds, volume: 0.05, lowpass: 0.9, attack: 0.5, release: 0.5, seed: 31))
        case .industrial:
            for _ in 0..<3 {
                let start = Double(rng.int(0...70)) / 10
                out = mix(out, mix(tone(Double(rng.int(180...320)), 0.4, volume: 0.05, release: 0.35), noise(0.08, volume: 0.1, lowpass: 0.4, seed: 41)), offset: Int(start * sampleRate))
            }
            out = mix(out, tone(60, seconds, volume: 0.03, attack: 0.5, release: 0.5))
        case .mine:
            for _ in 0..<6 {
                let start = Double(rng.int(0...75)) / 10
                out = mix(out, tone(Double(rng.int(1400...2000)), 0.08, volume: 0.06, release: 0.07, slide: -500), offset: Int(start * sampleRate))
            }
        case .depot, .mountain:
            break
        }
        return Array(out.prefix(Int(seconds * sampleRate)))
    }

    /// Gentle ambient music: slow pad chords and a sparse pentatonic melody. Seamless 32 s loop.
    static func music() -> [Float] {
        let bpm = 60.0
        let beat = 60 / bpm
        let barBeats = 8.0
        // Am – F – C – G (voicings in Hz)
        let chords: [[Double]] = [
            [220.00, 261.63, 329.63], [174.61, 220.00, 261.63],
            [196.00, 261.63, 329.63], [196.00, 246.94, 293.66],
        ]
        let seconds = beat * barBeats * Double(chords.count)
        var out = buffer(seconds)
        let n = out.count
        let barLen = Int(beat * barBeats * sampleRate)
        for (bar, chord) in chords.enumerated() {
            let start = bar * barLen
            for i in 0..<barLen {
                let t = Double(i) / sampleRate
                let a = min(1, t / 1.5) * min(1, (Double(barLen - i) / sampleRate) / 1.5)
                var s = 0.0
                for f in chord {
                    s += sin(2 * .pi * f * t) * 0.5 + sin(2 * .pi * f * 1.003 * t) * 0.5
                    s += sin(2 * .pi * f / 2 * t) * 0.3
                }
                let idx = start + i
                if idx < n { out[idx] += Float(s * a * 0.025) }
            }
        }
        // Melody: pentatonic A minor plucks.
        let scale: [Double] = [440, 523.25, 587.33, 659.25, 783.99, 880]
        var rng = SeededRandom(seed: 2147)
        var t = 1.0
        while t < seconds - 2 {
            let f = scale[rng.int(0...(scale.count - 1))]
            let dur = 1.2
            var pluck = buffer(dur)
            for i in 0..<pluck.count {
                let tt = Double(i) / sampleRate
                pluck[i] = Float((sin(2 * .pi * f * tt) + 0.3 * sin(2 * .pi * f * 2 * tt)) * exp(-tt * 3.2) * 0.07)
            }
            out = mix(out, pluck, offset: Int(t * sampleRate))
            t += beat * Double([1, 2, 2, 3, 4][rng.int(0...4)])
        }
        return Array(out.prefix(n))
    }
}
