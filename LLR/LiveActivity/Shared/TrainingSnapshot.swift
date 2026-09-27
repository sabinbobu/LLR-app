import Foundation

/// Written by the app, read by the Home Screen widget — the only thing crossing the App Group
/// boundary between the two processes. Deliberately tiny: the widget has no model container of its
/// own, so it never touches the SwiftData store directly.
struct TrainingSnapshot: Codable, Equatable {
    var streak: Int
    var trainedDaysThisMonth: [Date]
    var generatedAt: Date

    static let appGroupID = "group.com.sabinbobu.llr"
    private static let fileName = "training_snapshot.json"

    private static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }

    func write() {
        guard let url = Self.fileURL, let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func read() -> TrainingSnapshot? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TrainingSnapshot.self, from: data)
    }
}
