import SwiftData

extension WorkoutFactory {
    /// Persisted at once, like a lift, so an app kill mid-run loses nothing.
    static func startRun(in context: ModelContext) -> Workout {
        let run = Workout()
        run.sectionRaw = RunStats.sectionRaw
        context.insert(run)
        try? context.save()
        return run
    }

    @MainActor
    static func finishRun(_ run: Workout, in context: ModelContext) {
        run.endedAt = .now
        try? context.save()
        TrainingSnapshotSync.sync(context: context)
    }
}
