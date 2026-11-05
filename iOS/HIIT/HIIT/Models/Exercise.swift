import Foundation

enum ExerciseUnit: String, Codable, CaseIterable, Equatable, Sendable {
    case repetitions
    case seconds
    case minutes
}

struct Exercise: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var unit: ExerciseUnit
    var value: Int?

    init(
        id: UUID = UUID(),
        name: String,
        repetitions: Int?
    ) {
        self.id = id
        self.name = name
        self.unit = .repetitions
        self.value = repetitions
    }

    init(
        id: UUID = UUID(),
        name: String,
        seconds: Int?,
        displayedAs unit: ExerciseUnit
    ) {
        self.id = id
        self.name = name
        self.unit = unit == .repetitions ? .seconds : unit
        self.value = seconds
    }

    var isTimed: Bool {
        unit != .repetitions
    }

    var durationInSeconds: Int? {
        guard isTimed, let value, value > 0 else {
            return nil
        }
        return unit == .minutes ? value * 60 : value
    }

    var repetitions: Int? {
        guard unit == .repetitions else {
            return nil
        }
        return value
    }

    mutating func cycleUnit() {
        switch unit {
        case .repetitions:
            unit = .seconds
            value = 60
        case .seconds:
            let seconds = max(60, value ?? 60)
            unit = .minutes
            value = max(1, Int((Double(seconds) / 60).rounded()))
        case .minutes:
            unit = .repetitions
        }
    }

    func duration(fallbackForRepetitions fallback: Int) -> Int {
        if isTimed {
            return durationInSeconds ?? 60
        }
        return fallback
    }
}
