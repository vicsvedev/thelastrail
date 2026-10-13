import AVFoundation

/// Plays synthesized sound effects, ambience, train rumble and music.
/// If no audio device is available the game simply runs silently.
final class SoundManager {
    private let engine = AVAudioEngine()
    private let format: AVAudioFormat
    private var sfxPlayers: [AVAudioPlayerNode] = []
    private var nextSfx = 0
    private let musicPlayer = AVAudioPlayerNode()
    private let ambiencePlayer = AVAudioPlayerNode()
    private let trainPlayer = AVAudioPlayerNode()
    private let sfxMixer = AVAudioMixerNode()
    private let musicMixer = AVAudioMixerNode()
    private var effectBuffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var ambienceBuffers: [Region: AVAudioPCMBuffer] = [:]
    private var trainBuffer: AVAudioPCMBuffer?
    private var musicBuffer: AVAudioPCMBuffer?
    private var currentAmbience: Region?
    private var trainRunning = false
    private(set) var isAvailable = false
    private var settings = GameSettings()

    init() {
        format = AVAudioFormat(standardFormatWithSampleRate: SoundSynth.sampleRate, channels: 1)!
        setup()
    }

    private func setup() {
        // Ambient: respects the silent switch and mixes with other audio.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        engine.attach(sfxMixer)
        engine.attach(musicMixer)
        engine.connect(sfxMixer, to: engine.mainMixerNode, format: format)
        engine.connect(musicMixer, to: engine.mainMixerNode, format: format)
        for _ in 0..<8 {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            engine.connect(p, to: sfxMixer, format: format)
            sfxPlayers.append(p)
        }
        for p in [ambiencePlayer, trainPlayer] {
            engine.attach(p)
            engine.connect(p, to: sfxMixer, format: format)
        }
        engine.attach(musicPlayer)
        engine.connect(musicPlayer, to: musicMixer, format: format)
        do {
            try engine.start()
            isAvailable = true
        } catch {
            isAvailable = false
            return
        }
        for e in SoundEffect.allCases { effectBuffers[e] = makeBuffer(SoundSynth.effect(e)) }
        trainBuffer = makeBuffer(SoundSynth.trainLoop())
        // Music and ambience take a moment to synthesize; do it off the main thread.
        Task.detached(priority: .utility) {
            let music = SoundSynth.music()
            let regions: [Region] = [.depot, .forest, .industrial, .mine, .mountain]
            let ambiences = Dictionary(uniqueKeysWithValues: regions.map { ($0, SoundSynth.ambience($0)) })
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.musicBuffer = self.makeBuffer(music)
                for (r, samples) in ambiences { self.ambienceBuffers[r] = self.makeBuffer(samples) }
                self.startMusic()
                if let pending = self.currentAmbience {
                    self.currentAmbience = nil
                    self.setAmbience(pending)
                }
            }
        }
    }

    private func makeBuffer(_ samples: [Float]) -> AVAudioPCMBuffer? {
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else { return nil }
        buf.frameLength = AVAudioFrameCount(samples.count)
        if let ch = buf.floatChannelData?[0] {
            samples.withUnsafeBufferPointer { src in
                for i in 0..<samples.count { ch[i] = max(-1, min(1, src[i])) }
            }
        }
        return buf
    }

    /// Restarts the engine after an interruption (phone call, Siri, backgrounding).
    func resume() {
        guard isAvailable, !engine.isRunning else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        guard (try? engine.start()) != nil else { return }
        startMusic()
        if let region = currentAmbience { currentAmbience = nil; setAmbience(region) }
        if trainRunning { trainRunning = false; setTrainRunning(true) }
    }

    func apply(_ s: GameSettings) {
        settings = s
        guard isAvailable else { return }
        engine.mainMixerNode.outputVolume = s.muted ? 0 : Float(s.masterVolume)
        sfxMixer.outputVolume = Float(s.effectsVolume)
        musicMixer.outputVolume = Float(s.musicVolume)
    }

    func play(_ effect: SoundEffect, volume: Float = 1) {
        guard isAvailable, let buf = effectBuffers[effect] else { return }
        let p = sfxPlayers[nextSfx]
        nextSfx = (nextSfx + 1) % sfxPlayers.count
        p.stop()
        p.volume = volume
        p.scheduleBuffer(buf, at: nil, options: [])
        p.play()
    }

    private func startMusic() {
        guard isAvailable, let buf = musicBuffer else { return }
        musicPlayer.stop()
        musicPlayer.scheduleBuffer(buf, at: nil, options: .loops)
        musicPlayer.volume = 0.9
        musicPlayer.play()
    }

    func setAmbience(_ region: Region?) {
        guard currentAmbience != region || !ambiencePlayer.isPlaying else { return }
        currentAmbience = region
        guard isAvailable else { return }
        ambiencePlayer.stop()
        guard let region, let buf = ambienceBuffers[region] else { return }
        ambiencePlayer.volume = 0.8
        ambiencePlayer.scheduleBuffer(buf, at: nil, options: .loops)
        ambiencePlayer.play()
    }

    func setTrainRunning(_ running: Bool, intensity: Float = 1) {
        guard isAvailable else { return }
        trainPlayer.volume = 0.7 * intensity
        guard running != trainRunning else { return }
        trainRunning = running
        if running, let buf = trainBuffer {
            trainPlayer.scheduleBuffer(buf, at: nil, options: .loops)
            trainPlayer.play()
        } else {
            trainPlayer.stop()
        }
    }
}
