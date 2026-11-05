import Foundation

enum ExerciseSearch {
    static func normalize(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "fr_FR"))
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    static func isKnown(_ name: String, customNames: [String]) -> Bool {
        let key = normalize(name)
        return ExerciseCatalog.entries.contains { normalize($0.name) == key }
            || customNames.contains { normalize($0) == key }
    }

    static func remembered(_ name: String, in customNames: [String]) -> [String] {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2, !isKnown(trimmed, customNames: customNames) else {
            return customNames
        }
        return customNames + [trimmed]
    }

    static func suggestions(
        for query: String,
        customNames: [String],
        limit: Int = 8
    ) -> [ExerciseCatalogEntry] {
        let normalizedQuery = normalize(query)
        let customEntries = customNames.map {
            ExerciseCatalogEntry(name: $0, category: "Perso", isCustom: true)
        }
        let pool = customEntries + ExerciseCatalog.entries

        if normalizedQuery.isEmpty {
            return customEntries
                .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
                .prefix(limit)
                .map { $0 }
        }

        let words = normalizedQuery.split(separator: " ").map(String.init)
        let compactQuery = normalizedQuery.replacingOccurrences(of: " ", with: "")

        return pool.compactMap { entry -> (ExerciseCatalogEntry, Int)? in
            let candidate = normalize(entry.name)
            let score: Int
            if candidate.hasPrefix(normalizedQuery) {
                score = 0
            } else if (" " + candidate).contains(" " + normalizedQuery) {
                score = 1
            } else if candidate.contains(normalizedQuery) {
                score = 2
            } else if words.allSatisfy(candidate.contains) {
                score = 3
            } else if candidate.replacingOccurrences(of: " ", with: "").contains(compactQuery) {
                score = 4
            } else {
                return nil
            }
            return (entry, score)
        }
        .sorted {
            if $0.1 != $1.1 { return $0.1 < $1.1 }
            if $0.0.isCustom != $1.0.isCustom { return $0.0.isCustom }
            if $0.0.name.count != $1.0.name.count { return $0.0.name.count < $1.0.name.count }
            return $0.0.name.localizedCompare($1.0.name) == .orderedAscending
        }
        .prefix(limit)
        .map(\.0)
    }
}
