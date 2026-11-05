import Foundation

enum WorkoutMode: String, Codable, CaseIterable, Equatable, Sendable {
    case emom
    case amrap
}

struct WarmupConfiguration: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var minutes: Int
    var exercises: [Exercise]
}

struct AMRAPConfiguration: Codable, Equatable, Sendable {
    var minutes: Int
    var exercises: [Exercise]
}

struct FinisherConfiguration: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var repetitionExerciseMinutes: Int
    var exercises: [Exercise]
}

struct WorkoutConfiguration: Codable, Equatable, Sendable {
    var warmup: WarmupConfiguration
    var mode: WorkoutMode
    var amrap: AMRAPConfiguration
    var emomRounds: Int
    var emomExercises: [Exercise]
    var finisher: FinisherConfiguration
    var voiceAnnouncementsEnabled: Bool

    static let original = WorkoutConfiguration(
        warmup: WarmupConfiguration(
            isEnabled: true,
            minutes: 2,
            exercises: [
                Exercise(name: "Squat", repetitions: 10),
                Exercise(name: "Down up", repetitions: 10),
                Exercise(name: "Plank jack", repetitions: 10)
            ]
        ),
        mode: .emom,
        amrap: AMRAPConfiguration(
            minutes: 12,
            exercises: [
                Exercise(name: "Burpees", repetitions: 10),
                Exercise(name: "Squat jump", repetitions: 15),
                Exercise(name: "Mountain climber", repetitions: 20)
            ]
        ),
        emomRounds: 5,
        emomExercises: [
            Exercise(name: "Burpees", repetitions: 12),
            Exercise(name: "Squat jump", repetitions: 25),
            Exercise(name: "Mountain climber", repetitions: 30),
            Exercise(name: "Jumping jack", repetitions: 50),
            Exercise(name: "Step up", seconds: 1, displayedAs: .minutes)
        ],
        finisher: FinisherConfiguration(
            isEnabled: true,
            repetitionExerciseMinutes: 1,
            exercises: [
                Exercise(name: "Push up", seconds: 1, displayedAs: .minutes),
                Exercise(name: "Plank", seconds: 1, displayedAs: .minutes)
            ]
        ),
        voiceAnnouncementsEnabled: true
    )

    mutating func validate() {
        warmup.minutes = min(max(warmup.minutes, 1), 15)
        amrap.minutes = min(max(amrap.minutes, 1), 60)
        emomRounds = min(max(emomRounds, 1), 20)
        finisher.repetitionExerciseMinutes = min(max(finisher.repetitionExerciseMinutes, 1), 5)

        if warmup.exercises.isEmpty {
            warmup.exercises = Self.original.warmup.exercises
        }
        if amrap.exercises.isEmpty {
            amrap.exercises = Self.original.amrap.exercises
        }
        if emomExercises.isEmpty {
            emomExercises = Self.original.emomExercises
        }
        if finisher.exercises.isEmpty {
            finisher.exercises = Self.original.finisher.exercises
        }
    }
}
