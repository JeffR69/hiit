import AVFAudio
import Foundation

@MainActor
final class WorkoutAudio: NSObject {
    struct SpeechPart {
        let text: String
        let language: String
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let synthesizer = AVSpeechSynthesizer()
    private var speechTask: Task<Void, Never>?

    override init() {
        super.init()
        engine.attach(player)
        try? engine.connectNode(player, to: engine.mainMixerNode, format: nil)
    }

    func shortBeep() {
        play([(880, 0.12, 0)])
    }

    func longBeep() {
        play([(660, 0.18, 0), (990, 0.5, 0.2)])
    }

    func completionBeep() {
        play([(660, 0.2, 0), (880, 0.2, 0.25), (1175, 0.6, 0.5)])
    }

    func roundBeep() {
        play([(1046, 0.1, 0)])
    }

    func speak(_ parts: [SpeechPart], after delay: TimeInterval = 0) {
        stopSpeech()
        let queuedParts = parts.filter { !$0.text.isEmpty }
        speechTask = Task {
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            guard !Task.isCancelled else { return }

            for part in queuedParts {
                let utterance = AVSpeechUtterance(string: part.text)
                utterance.voice = AVSpeechSynthesisVoice(language: part.language)
                utterance.rate = part.language.hasPrefix("en") ? 0.5 : 0.525
                synthesizer.speak(utterance)
            }
        }
    }

    func stopSpeech() {
        speechTask?.cancel()
        speechTask = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func play(_ tones: [(frequency: Double, duration: Double, delay: Double)]) {
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else { return }
        if !engine.isRunning {
            try? engine.start()
        }

        for tone in tones {
            let frameCount = AVAudioFrameCount((tone.duration + tone.delay) * format.sampleRate)
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: frameCount
            ) else { continue }
            buffer.frameLength = frameCount
            guard let channels = buffer.floatChannelData else { continue }

            for frame in 0..<Int(frameCount) {
                let time = Double(frame) / format.sampleRate
                let sample: Float
                if time < tone.delay {
                    sample = 0
                } else {
                    let localTime = time - tone.delay
                    let fade = max(0, 1 - localTime / tone.duration)
                    sample = Float(sin(2 * Double.pi * tone.frequency * localTime) * 0.25 * fade)
                }
                for channel in 0..<Int(format.channelCount) {
                    channels[channel][frame] = sample
                }
            }
            player.scheduleBuffer(buffer)
        }
        if !player.isPlaying {
            try? player.playAudio()
        }
    }
}
