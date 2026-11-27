import Foundation

/// What tapping Finish on a gym workout would do to the sets that aren't ticked.
enum FinishCheck: Equatable {
    /// Finishing now would delete the whole workout.
    case nothingLogged
    case ready
    case dropsUnticked(Int)

    init(ticked: Int, total: Int) {
        if ticked == 0 {
            self = .nothingLogged
        } else if ticked < total {
            self = .dropsUnticked(total - ticked)
        } else {
            self = .ready
        }
    }

    init(_ workout: Workout) {
        let sets = workout.exercises.flatMap(\.sets)
        self.init(ticked: sets.filter { $0.completedAt != nil }.count, total: sets.count)
    }

    var warning: String? {
        guard case .dropsUnticked(let count) = self else { return nil }
        return "\(count) unticked \(count == 1 ? "set" : "sets") will be removed."
    }
}
