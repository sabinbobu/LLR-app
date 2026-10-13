import Foundation
import Observation

/// One timer for the process, shared by the workout screen and the Lock Screen buttons, so a rest
/// started or skipped in either place is the same rest in both.
@MainActor
@Observable
final class RestTimer {
    static let shared = RestTimer()

    private(set) var startDate: Date?
    private(set) var endDate: Date?
    /// Bumped only on natural expiry so the view can fire a haptic without firing on Skip.
    private(set) var finishedCount = 0
    private var task: Task<Void, Never>?
    private var exerciseName: String?

    private init() {}

    var isRunning: Bool { endDate != nil }

    func start(seconds: Int, exerciseName: String? = nil) {
        self.exerciseName = exerciseName
        startDate = .now
        endDate = .now.addingTimeInterval(TimeInterval(seconds))
        schedule()
    }

    /// Picks up a rest that outlived the process; the notification for it is already scheduled.
    func restore(start: Date, end: Date) {
        guard endDate == nil, end > .now else { return }
        startDate = start
        endDate = end
        scheduleExpiry(at: end)
    }

    func adjust(by seconds: Int) {
        guard let endDate else { return }
        let adjusted = endDate.addingTimeInterval(TimeInterval(seconds))
        if adjusted <= .now {
            skip()
        } else {
            self.endDate = adjusted
            schedule()
        }
    }

    func skip() {
        task?.cancel()
        RestNotifier.cancel()
        startDate = nil
        endDate = nil
        LiveWorkoutActivity.sync()
    }

    private func schedule() {
        RestNotifier.cancel()
        guard let endDate else { return }
        RestNotifier.schedule(after: endDate.timeIntervalSinceNow, exerciseName: exerciseName)
        scheduleExpiry(at: endDate)
        LiveWorkoutActivity.sync()
    }

    private func scheduleExpiry(at endDate: Date) {
        task?.cancel()
        task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(endDate.timeIntervalSinceNow))
            guard !Task.isCancelled, let self else { return }
            self.startDate = nil
            self.endDate = nil
            self.finishedCount += 1
            RestSound.play()
            LiveWorkoutActivity.sync()
        }
    }
}
