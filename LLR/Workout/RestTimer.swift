import Foundation
import Observation

@MainActor
@Observable
final class RestTimer {
    private(set) var startDate: Date?
    private(set) var endDate: Date?
    /// Bumped only on natural expiry so the view can fire a haptic without firing on Skip.
    private(set) var finishedCount = 0
    private var task: Task<Void, Never>?

    var isRunning: Bool { endDate != nil }

    func start(seconds: Int) {
        startDate = .now
        endDate = .now.addingTimeInterval(TimeInterval(seconds))
        schedule()
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
        startDate = nil
        endDate = nil
    }

    private func schedule() {
        task?.cancel()
        guard let endDate else { return }
        task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(endDate.timeIntervalSinceNow))
            guard !Task.isCancelled, let self else { return }
            self.startDate = nil
            self.endDate = nil
            self.finishedCount += 1
        }
    }
}
