import Foundation

enum SetKind: String, CaseIterable, Identifiable {
    case normal, warmup, drop, failure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: "Normal Set"
        case .warmup: "Warm-up Set"
        case .drop: "Drop Set"
        case .failure: "Failure Set"
        }
    }

    var badge: String? {
        switch self {
        case .normal: nil
        case .warmup: "W"
        case .drop: "D"
        case .failure: "F"
        }
    }

    /// Warm-ups are deliberately light; counting them would drag charts down and fake PR comparisons.
    var countsTowardProgress: Bool { self != .warmup }

    /// Working sets are numbered 1, 2, 3… with warm-ups skipped, so "set 2" means the same thing every session.
    static func labels(for kinds: [SetKind]) -> [String] {
        var working = 0
        return kinds.map { kind in
            if kind.countsTowardProgress { working += 1 }
            return kind.badge ?? "\(working)"
        }
    }
}
