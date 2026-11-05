import Foundation

enum WorkoutSegmentKind: String, Codable, Equatable, Sendable {
    case warmup
    case emom
    case amrap
    case finisher
}

struct WorkoutSegment: Identifiable, Equatable, Sendable {
    let id: Int
    let kind: WorkoutSegmentKind
    let duration: Int
    let startTime: Int
    let round: Int?
    let exerciseIndex: Int?
    let exercise: Exercise?

    var endTime: Int {
        startTime + duration
    }
}

struct WorkoutPlan: Equatable, Sendable {
    let segments: [WorkoutSegment]
    let totalDuration: Int

    func segmentIndex(at elapsedSeconds: Double) -> Int? {
        guard elapsedSeconds >= 0, elapsedSeconds < Double(totalDuration) else {
            return nil
        }
        return segments.firstIndex {
            elapsedSeconds < Double($0.endTime)
        }
    }
}
