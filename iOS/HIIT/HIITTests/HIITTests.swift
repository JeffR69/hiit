import Foundation
import Testing
@testable import HIIT

struct WorkoutPlanTests {
    @Test func originalConfigurationMatchesWebDuration() {
        let configuration = WorkoutConfiguration.original

        #expect(WorkoutPlanBuilder.warmupDuration(for: configuration) == 120)
        #expect(WorkoutPlanBuilder.mainDuration(for: configuration) == 1_500)
        #expect(WorkoutPlanBuilder.finisherDuration(for: configuration) == 120)
        #expect(WorkoutPlanBuilder.totalDuration(for: configuration) == 1_740)
    }

    @Test func originalEMOMPlanMatchesWebSegments() {
        let plan = WorkoutPlanBuilder.build(from: .original)

        #expect(plan.segments.count == 28)
        #expect(plan.totalDuration == 1_740)
        #expect(plan.segments.first?.kind == .warmup)
        #expect(plan.segments[1].round == 1)
        #expect(plan.segments[5].exercise?.name == "Step up")
        #expect(plan.segments[5].duration == 60)
        #expect(plan.segments.last?.kind == .finisher)
    }

    @Test func amrapReplacesEMOMAndKeepsOptionalPhases() {
        var configuration = WorkoutConfiguration.original
        configuration.mode = .amrap

        let plan = WorkoutPlanBuilder.build(from: configuration)

        #expect(plan.segments.map(\.kind) == [.warmup, .amrap, .finisher, .finisher])
        #expect(plan.totalDuration == 120 + 720 + 120)
    }

    @Test func disabledOptionalPhasesAreExcluded() {
        var configuration = WorkoutConfiguration.original
        configuration.warmup.isEnabled = false
        configuration.finisher.isEnabled = false

        let plan = WorkoutPlanBuilder.build(from: configuration)

        #expect(plan.segments.count == 25)
        #expect(plan.totalDuration == 1_500)
        #expect(plan.segments.allSatisfy { $0.kind == .emom })
    }

    @Test func timedExerciseUsesOwnDuration() {
        let exercises = [
            Exercise(name: "A", repetitions: 10),
            Exercise(name: "B", seconds: 45, displayedAs: .seconds),
            Exercise(name: "C", seconds: 2, displayedAs: .minutes)
        ]

        #expect(
            WorkoutPlanBuilder.duration(of: exercises, repetitionDuration: 60) == 225
        )
    }

    @Test func segmentLookupUsesHalfOpenIntervals() {
        let plan = WorkoutPlanBuilder.build(from: .original)

        #expect(plan.segmentIndex(at: 0) == 0)
        #expect(plan.segmentIndex(at: 119.999) == 0)
        #expect(plan.segmentIndex(at: 120) == 1)
        #expect(plan.segmentIndex(at: Double(plan.totalDuration)) == nil)
    }
}

struct ExerciseTests {
    @Test func unitCycleMatchesWeb() {
        var exercise = Exercise(name: "Test", repetitions: 12)

        exercise.cycleUnit()
        #expect(exercise.unit == .seconds)
        #expect(exercise.value == 60)

        exercise.value = 91
        exercise.cycleUnit()
        #expect(exercise.unit == .minutes)
        #expect(exercise.value == 2)

        exercise.cycleUnit()
        #expect(exercise.unit == .repetitions)
        #expect(exercise.value == 2)
    }

    @Test func invalidTimedValueFallsBackToOneMinute() {
        let exercise = Exercise(name: "Test", seconds: nil, displayedAs: .seconds)
        #expect(exercise.duration(fallbackForRepetitions: 180) == 60)
    }

    @Test func validationAppliesWebLimitsAndRestoresEmptyLists() {
        var configuration = WorkoutConfiguration.original
        configuration.warmup.minutes = 0
        configuration.amrap.minutes = 100
        configuration.emomRounds = 0
        configuration.finisher.repetitionExerciseMinutes = 10
        configuration.emomExercises = []

        configuration.validate()

        #expect(configuration.warmup.minutes == 1)
        #expect(configuration.amrap.minutes == 60)
        #expect(configuration.emomRounds == 1)
        #expect(configuration.finisher.repetitionExerciseMinutes == 5)
        #expect(!configuration.emomExercises.isEmpty)
    }
}

struct ExerciseSearchTests {
    @Test func normalizationMatchesAccentsHyphensAndWhitespace() {
        #expect(ExerciseSearch.normalize("  Élastique-test  ") == "elastique test")
    }

    @Test func customExerciseIsRememberedOnlyOnce() {
        let first = ExerciseSearch.remembered("Mon mouvement", in: [])
        let second = ExerciseSearch.remembered("mon mouvement", in: first)

        #expect(first == ["Mon mouvement"])
        #expect(second == first)
    }

    @Test func catalogExerciseIsNotStoredAsCustom() {
        #expect(ExerciseSearch.remembered("Squat", in: []).isEmpty)
        #expect(ExerciseSearch.remembered("squât", in: []).isEmpty)
    }

    @Test func prefixResultsComeBeforeInternalMatches() {
        let results = ExerciseSearch.suggestions(
            for: "squat",
            customNames: ["Mon squat spécial"]
        )

        #expect(results.count <= 8)
        #expect(results.first?.name == "Squat")
        #expect(results.contains { $0.name == "Mon squat spécial" })
    }

    @Test func emptyQueryReturnsOnlyCustomExercisesAlphabetically() {
        let results = ExerciseSearch.suggestions(
            for: "",
            customNames: ["Zulu", "Alpha"]
        )

        #expect(results.map { $0.name } == ["Alpha", "Zulu"])
        #expect(results.allSatisfy { $0.isCustom })
    }
}

struct DurationFormatterTests {
    @Test(arguments: [
        (45, "45 s"),
        (60, "1 min"),
        (65, "1 min 05")
    ])
    func shortFormat(input: (Int, String)) {
        #expect(WorkoutDurationFormatter.short(input.0) == input.1)
    }

    @Test func clockFormat() {
        #expect(WorkoutDurationFormatter.clock(65) == "1:05")
    }

    @Test func spokenFormat() {
        #expect(WorkoutDurationFormatter.spoken(60) == "une minute")
        #expect(WorkoutDurationFormatter.spoken(125) == "2 minutes 5 secondes")
    }

    @Test func zeroSecondsHasEmptySpokenFormat() {
        #expect(WorkoutDurationFormatter.spoken(0).isEmpty)
    }
}
