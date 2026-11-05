import Foundation

enum WorkoutDurationFormatter {
    static func short(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60

        if minutes == 0 {
            return "\(remainder) s"
        }
        if remainder == 0 {
            return "\(minutes) min"
        }
        return "\(minutes) min \(String(format: "%02d", remainder))"
    }

    static func clock(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return "\(minutes):\(String(format: "%02d", remainder))"
    }

    static func spoken(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        var components: [String] = []

        if minutes > 0 {
            components.append(minutes == 1 ? "une minute" : "\(minutes) minutes")
        }
        if remainder > 0 {
            components.append("\(remainder) secondes")
        }
        return components.joined(separator: " ")
    }
}
