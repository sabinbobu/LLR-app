import Foundation

/// Which scale the optional effort column asks for. Off by default: rating a set is a third tap
/// the core loop doesn't need.
enum EffortScale: String, CaseIterable, Identifiable {
    case off, rir, rpe

    var id: String { rawValue }
    var title: String {
        switch self {
        case .off: "Off"
        case .rir: "RIR"
        case .rpe: "RPE"
        }
    }
}

/// How hard a set was, stored as reps in reserve. RIR is the internal unit because it has a real
/// zero (a set taken to failure); RPE 8 and RIR 2 are the same set.
enum Effort {
    /// At or below this a set is close enough to failure to count as hard.
    static let hardRir = 3.0

    struct Band: Equatable {
        /// What a quick pick logs.
        let rir: Double
        /// The band's inclusive upper bound, so a typed or imported in-between value still lands in one.
        let upTo: Double
        let feel: String
    }

    /// Fine near failure, where half a rep changes the training, and one bucket from 4 up, where
    /// nobody can tell 5 in reserve from 7.
    static let bands = [
        Band(rir: 0, upTo: 0.25, feel: "To failure, nothing left"),
        Band(rir: 0.5, upTo: 0.75, feel: "Maybe half a rep left"),
        Band(rir: 1, upTo: 1.5, feel: "One more rep"),
        Band(rir: 2, upTo: 2.5, feel: "Two more reps"),
        Band(rir: 3, upTo: 3.5, feel: "Three more reps"),
        Band(rir: 4, upTo: .infinity, feel: "Four or more, easy"),
    ]

    static func bandIndex(for rir: Double) -> Int {
        bands.firstIndex { rir <= $0.upTo } ?? bands.count - 1
    }

    static func isHard(_ rir: Double?) -> Bool {
        rir.map { $0 <= hardRir } ?? false
    }

    /// nil for anything off the 1–10 scale, so a stray value in an import isn't read as a rating.
    static func rir(fromRPE rpe: Double) -> Double? {
        (1...10).contains(rpe) ? 10 - rpe : nil
    }

    /// The top RIR bucket reads "4+": a tap there logs 4, but it stands for everything easier.
    static func text(rir: Double, scale: EffortScale) -> String {
        if scale == .rpe { return number(10 - rir) }
        return rir >= 4 ? "4+" : number(rir)
    }

    private static func number(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded() ? String(Int(rounded)) : String(format: "%.1f", rounded)
    }
}
