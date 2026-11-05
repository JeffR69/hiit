import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class WorkoutSession {
    enum Screen: Equatable {
        case setup
        case running
        case completed
    }

    let configuration: WorkoutConfiguration
    let plan: WorkoutPlan

    private(set) var screen: Screen = .setup
    private(set) var elapsedSeconds = 0.0
    private(set) var currentSegmentIndex = 0
    private(set) var isPaused = false
    private(set) var isStopArmed = false
    private(set) var amrapRounds = 0

    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private var lastUptime = 0.0
    @ObservationIgnored private var lastDisplayedSecond: Int?
    @ObservationIgnored private let audio = WorkoutAudio()

    init(configuration: WorkoutConfiguration) {
        self.configuration = configuration
        plan = WorkoutPlanBuilder.build(from: configuration)
    }

    var currentSegment: WorkoutSegment {
        plan.segments[currentSegmentIndex]
    }

    var remainingSeconds: Int {
        max(0, Int(ceil(Double(currentSegment.endTime) - elapsedSeconds)))
    }

    var progress: Double {
        let segmentElapsed = elapsedSeconds - Double(currentSegment.startTime)
        return max(0, min(1, 1 - segmentElapsed / Double(currentSegment.duration)))
    }

    var nextDescription: String {
        guard currentSegmentIndex + 1 < plan.segments.count else {
            return currentSegment.duration == 60
                ? "Dernière minute !"
                : "Dernier exercice !"
        }
        let next = plan.segments[currentSegmentIndex + 1]
        if next.kind == .amrap {
            return "Ensuite : AMRAP \(configuration.amrap.minutes) min"
        }
        guard let exercise = next.exercise else {
            return "Ensuite : Échauffement"
        }
        let amount = exercise.repetitions.map { "× \($0)" }
            ?? WorkoutDurationFormatter.short(next.duration)
        let prefix = next.kind == .finisher && next.exerciseIndex == 0
            ? "Finisher · "
            : ""
        let round = next.kind == .emom && next.exerciseIndex == 0
            ? " (round \(next.round ?? 1))"
            : ""
        return "Ensuite : \(prefix)\(exercise.name.isEmpty ? "Exercice" : exercise.name) \(amount)\(round)"
    }

    func start() {
        guard !plan.segments.isEmpty else { return }
        screen = .running
        elapsedSeconds = 0
        currentSegmentIndex = 0
        lastUptime = ProcessInfo.processInfo.systemUptime
        setScreenAwake(true)
        enterSegment()
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                self?.tick()
            }
        }
    }

    func togglePause() {
        isPaused.toggle()
        lastUptime = ProcessInfo.processInfo.systemUptime
        if isPaused {
            audio.stopSpeech()
        }
    }

    func skip() {
        guard currentSegmentIndex + 1 < plan.segments.count else {
            finish()
            return
        }
        elapsedSeconds = Double(plan.segments[currentSegmentIndex + 1].startTime)
        currentSegmentIndex += 1
        enterSegment()
    }

    func goBack() {
        let segment = currentSegment
        if elapsedSeconds - Double(segment.startTime) <= 3, currentSegmentIndex > 0 {
            currentSegmentIndex -= 1
        }
        elapsedSeconds = Double(plan.segments[currentSegmentIndex].startTime)
        enterSegment()
    }

    func addAMRAPRound() {
        amrapRounds += 1
        audio.roundBeep()
    }

    func removeAMRAPRound() {
        amrapRounds = max(0, amrapRounds - 1)
    }

    func requestStop() {
        if isStopArmed {
            stop()
            return
        }
        isStopArmed = true
        Task {
            try? await Task.sleep(for: .seconds(3))
            isStopArmed = false
        }
    }

    func stop() {
        ticker?.cancel()
        audio.stopSpeech()
        setScreenAwake(false)
        screen = .setup
    }

    func finish() {
        ticker?.cancel()
        setScreenAwake(false)
        audio.completionBeep()
        let result = configuration.mode == .amrap
            ? "Séance terminée. \(amrapRounds) \(amrapRounds > 1 ? "tours" : "tour"). Bravo !"
            : "Séance terminée. Bravo !"
        if configuration.voiceAnnouncementsEnabled {
            audio.speak([.init(text: result, language: "fr-FR")], after: 0.8)
        }
        screen = .completed
    }

    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        if !isPaused {
            elapsedSeconds += now - lastUptime
        }
        lastUptime = now

        if elapsedSeconds >= Double(plan.totalDuration) {
            finish()
            return
        }
        if let index = plan.segmentIndex(at: elapsedSeconds),
           index != currentSegmentIndex {
            currentSegmentIndex = index
            enterSegment()
        }

        let seconds = remainingSeconds
        if seconds != lastDisplayedSecond {
            lastDisplayedSecond = seconds
            if !isPaused, (1...3).contains(seconds) {
                audio.shortBeep()
            }
            guard !isPaused, configuration.voiceAnnouncementsEnabled else { return }
            if (currentSegment.kind == .warmup || currentSegment.kind == .amrap),
               seconds == 10 {
                audio.speak([.init(text: "Dix secondes", language: "fr-FR")])
            }
            if currentSegment.kind == .amrap,
               currentSegment.duration > 120,
               seconds == 60 {
                audio.speak([.init(text: "Plus qu’une minute", language: "fr-FR")])
            }
            if currentSegment.kind == .amrap,
               currentSegment.duration >= 600,
               seconds * 2 == currentSegment.duration {
                let tours = "\(amrapRounds) \(amrapRounds > 1 ? "tours" : "tour")"
                audio.speak([.init(text: "Mi-temps. \(tours)", language: "fr-FR")])
            }
        }
    }

    private func enterSegment() {
        lastDisplayedSecond = nil
        audio.longBeep()
        guard configuration.voiceAnnouncementsEnabled else { return }
        let segment = currentSegment
        var parts: [WorkoutAudio.SpeechPart] = []

        switch segment.kind {
        case .warmup:
            parts.append(.init(
                text: "Échauffement, \(configuration.warmup.minutes) minutes.",
                language: "fr-FR"
            ))
            parts += listSpeech(configuration.warmup.exercises)
        case .amrap:
            parts.append(.init(
                text: "AMRAP, \(configuration.amrap.minutes) minutes.",
                language: "fr-FR"
            ))
            parts += listSpeech(configuration.amrap.exercises)
            parts.append(.init(text: "Partez !", language: "fr-FR"))
        case .emom, .finisher:
            var intro = ""
            if segment.kind == .finisher, segment.exerciseIndex == 0 {
                intro = "Finisher."
            } else if segment.kind == .emom, segment.exerciseIndex == 0 {
                intro = "Round \(segment.round ?? 1)."
            }
            if currentSegmentIndex == plan.segments.count - 1 {
                intro += segment.duration == 60
                    ? " Dernière minute."
                    : " Dernier exercice."
            }
            parts.append(.init(text: intro, language: "fr-FR"))
            if let exercise = segment.exercise {
                parts.append(.init(
                    text: exercise.name.isEmpty ? "Exercice" : exercise.name,
                    language: "en-US"
                ))
                if let repetitions = exercise.repetitions {
                    parts.append(.init(
                        text: "\(repetitions) répétitions",
                        language: "fr-FR"
                    ))
                } else {
                    parts.append(.init(
                        text: "pendant \(WorkoutDurationFormatter.spoken(segment.duration))",
                        language: "fr-FR"
                    ))
                }
            }
        }
        audio.speak(parts, after: 0.7)
    }

    private func listSpeech(_ exercises: [Exercise]) -> [WorkoutAudio.SpeechPart] {
        exercises.flatMap { exercise -> [WorkoutAudio.SpeechPart] in
            if let repetitions = exercise.repetitions {
                return [
                    .init(text: "\(repetitions)", language: "fr-FR"),
                    .init(
                        text: exercise.name.isEmpty ? "Exercice" : exercise.name,
                        language: "en-US"
                    )
                ]
            }
            return [
                .init(
                    text: exercise.name.isEmpty ? "Exercice" : exercise.name,
                    language: "en-US"
                ),
                .init(
                    text: WorkoutDurationFormatter.spoken(
                        exercise.duration(fallbackForRepetitions: 60)
                    ),
                    language: "fr-FR"
                )
            ]
        }
    }

    private func setScreenAwake(_ awake: Bool) {
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = awake
        #endif
    }
}
