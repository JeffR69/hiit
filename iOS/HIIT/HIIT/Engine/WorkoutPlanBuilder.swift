import Foundation

enum WorkoutPlanBuilder {
    static func duration(of exercises: [Exercise], repetitionDuration: Int) -> Int {
        exercises.reduce(0) {
            $0 + $1.duration(fallbackForRepetitions: repetitionDuration)
        }
    }

    static func warmupDuration(for configuration: WorkoutConfiguration) -> Int {
        configuration.warmup.isEnabled ? configuration.warmup.minutes * 60 : 0
    }

    static func mainDuration(for configuration: WorkoutConfiguration) -> Int {
        switch configuration.mode {
        case .emom:
            return configuration.emomRounds * duration(
                of: configuration.emomExercises,
                repetitionDuration: 60
            )
        case .amrap:
            return configuration.amrap.minutes * 60
        }
    }

    static func finisherDuration(for configuration: WorkoutConfiguration) -> Int {
        guard configuration.finisher.isEnabled else {
            return 0
        }
        return duration(
            of: configuration.finisher.exercises,
            repetitionDuration: configuration.finisher.repetitionExerciseMinutes * 60
        )
    }

    static func totalDuration(for configuration: WorkoutConfiguration) -> Int {
        warmupDuration(for: configuration)
            + mainDuration(for: configuration)
            + finisherDuration(for: configuration)
    }

    static func build(from configuration: WorkoutConfiguration) -> WorkoutPlan {
        var segments: [WorkoutSegment] = []
        var startTime = 0

        func append(
            kind: WorkoutSegmentKind,
            duration: Int,
            round: Int? = nil,
            exerciseIndex: Int? = nil,
            exercise: Exercise? = nil
        ) {
            segments.append(
                WorkoutSegment(
                    id: segments.count,
                    kind: kind,
                    duration: duration,
                    startTime: startTime,
                    round: round,
                    exerciseIndex: exerciseIndex,
                    exercise: exercise
                )
            )
            startTime += duration
        }

        if configuration.warmup.isEnabled {
            append(
                kind: .warmup,
                duration: configuration.warmup.minutes * 60
            )
        }

        switch configuration.mode {
        case .emom:
            for round in 1...configuration.emomRounds {
                for (index, exercise) in configuration.emomExercises.enumerated() {
                    append(
                        kind: .emom,
                        duration: exercise.duration(fallbackForRepetitions: 60),
                        round: round,
                        exerciseIndex: index,
                        exercise: exercise
                    )
                }
            }
        case .amrap:
            append(
                kind: .amrap,
                duration: configuration.amrap.minutes * 60
            )
        }

        if configuration.finisher.isEnabled {
            let fallback = configuration.finisher.repetitionExerciseMinutes * 60
            for (index, exercise) in configuration.finisher.exercises.enumerated() {
                append(
                    kind: .finisher,
                    duration: exercise.duration(fallbackForRepetitions: fallback),
                    exerciseIndex: index,
                    exercise: exercise
                )
            }
        }

        return WorkoutPlan(segments: segments, totalDuration: startTime)
    }
}
