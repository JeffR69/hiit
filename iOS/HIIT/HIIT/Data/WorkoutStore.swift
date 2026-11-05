import Foundation
import Observation
import SwiftUI

enum AppAppearance: String, Codable, CaseIterable, Equatable, Sendable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@MainActor
@Observable
final class WorkoutStore {
    private enum Keys {
        static let configuration = "native-workout-configuration-v1"
        static let customExercises = "native-custom-exercises-v1"
        static let appearance = "native-appearance-v1"
    }

    private let defaults: UserDefaults

    var configuration: WorkoutConfiguration {
        didSet { persistConfiguration() }
    }

    var customExerciseNames: [String] {
        didSet { persistCustomExercises() }
    }

    var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: Keys.configuration),
           var decoded = try? JSONDecoder().decode(WorkoutConfiguration.self, from: data) {
            decoded.validate()
            configuration = decoded
        } else {
            configuration = .original
        }

        customExerciseNames = defaults.stringArray(forKey: Keys.customExercises) ?? []
        appearance = AppAppearance(
            rawValue: defaults.string(forKey: Keys.appearance) ?? ""
        ) ?? .system

        rememberConfiguredExercises()
    }

    func resetConfiguration() {
        configuration = .original
    }

    func rememberExercise(named name: String) {
        customExerciseNames = ExerciseSearch.remembered(name, in: customExerciseNames)
    }

    func forgetExercise(named name: String) {
        customExerciseNames.removeAll { $0 == name }
    }

    private func rememberConfiguredExercises() {
        let lists = [
            configuration.warmup.exercises,
            configuration.emomExercises,
            configuration.amrap.exercises,
            configuration.finisher.exercises
        ]
        for exercise in lists.flatMap({ $0 }) {
            customExerciseNames = ExerciseSearch.remembered(
                exercise.name,
                in: customExerciseNames
            )
        }
    }

    private func persistConfiguration() {
        guard let data = try? JSONEncoder().encode(configuration) else {
            return
        }
        defaults.set(data, forKey: Keys.configuration)
    }

    private func persistCustomExercises() {
        defaults.set(customExerciseNames, forKey: Keys.customExercises)
    }
}
