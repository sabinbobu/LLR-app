import Foundation

/// Written by the app, read by the Home Screen widget — the only thing crossing the App Group
/// boundary between the two processes. Deliberately tiny: the widget has no model container of its
/// own, so it never touches the SwiftData store directly.
struct TrainingSnapshot: Codable, Equatable {
    var streak: Int
    var trainedDaysThisMonth: [Date]
    var generatedAt: Date
    /// Newest workout start. Optional so snapshots written before it existed still decode.
    var lastTrainedAt: Date? = nil

    /// The stored streak as of `now`. The widget can sit for weeks without the app writing a new
    /// snapshot, so a streak with no training this week or last has lapsed even though the file says otherwise.
    func streak(asOf now: Date, calendar: Calendar = .current) -> Int {
        guard let lastTrainedAt,
              let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
              let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeek)
        else { return streak }
        return lastTrainedAt >= lastWeek ? streak : 0
    }

    static let appGroupID = "group.com.sabinbobu.llr"
    private static let fileName = "training_snapshot.json"

    static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }

    func write(to url: URL? = TrainingSnapshot.fileURL) {
        guard let url, let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func read(from url: URL? = TrainingSnapshot.fileURL) -> TrainingSnapshot? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TrainingSnapshot.self, from: data)
    }
}
