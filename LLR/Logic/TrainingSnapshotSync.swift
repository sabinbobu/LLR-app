import SwiftData
import WidgetKit

/// Feeds the Home Screen streak widget after anything that could change the streak: finishing a
/// workout, or the app leaving the foreground (in case the Lock Screen or a background task changed
/// something the widget cares about since the last sync).
enum TrainingSnapshotSync {
    @MainActor
    static func sync(context: ModelContext) {
        let descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.endedAt != nil && $0.sectionRaw == "gym" })
        let starts = (try? context.fetch(descriptor))?.map(\.startedAt) ?? []
        TrainingSnapshot(
            streak: TrainingCalendar.weekStreak(workouts: starts),
            trainedDaysThisMonth: Array(TrainingCalendar.trainedDays(in: .now, workouts: starts)),
            generatedAt: .now
        ).write()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
