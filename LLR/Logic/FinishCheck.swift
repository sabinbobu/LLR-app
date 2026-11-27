import Foundation

/// What tapping Finish on a gym workout would do to the sets that aren't ticked.
enum FinishCheck: Equatable {
    case nothingLogged
    case ready
    case dropsUnticked(Int)

    init(ticked: Int, total: Int) {
        self = .ready
    }

    init(_ workout: Workout) {
        let sets = workout.exercises.flatMap(\.sets)
        self.init(ticked: sets.filter { $0.completedAt != nil }.count, total: sets.count)
    }

    var warning: String? { nil }
}
