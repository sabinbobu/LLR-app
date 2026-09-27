import Foundation

/// Groupings for the body map, recovery model and muscle-split radar — kept separate from
/// `MuscleGroup`'s exercise-library role in `ExerciseLibrary.swift`.
extension MuscleGroup {
    /// Cardio, Full Body and Other describe *how* an exercise trains, not a drawable muscle —
    /// excluded from the body map, recovery and the radar.
    var isTrainable: Bool {
        switch self {
        case .cardio, .fullBody, .other: false
        default: true
        }
    }

    enum Region: String, CaseIterable, Identifiable {
        case push = "Push", pull = "Pull", legs = "Legs", core = "Core", accessories = "Accessories"
        var id: String { rawValue }
    }

    var region: Region? {
        switch self {
        case .chest, .shoulders, .triceps: .push
        case .upperBack, .lats, .traps, .biceps, .forearms: .pull
        case .quadriceps, .hamstrings, .glutes, .calves, .abductors, .adductors: .legs
        case .abdominals: .core
        case .neck, .lowerBack: .accessories
        case .cardio, .fullBody, .other: nil
        }
    }

    /// The 12 groupings the muscle-split radar plots — coarser than `region`, so muscles that are
    /// nearly always trained together (e.g. the whole back) read as one axis instead of crowding four.
    enum RadarAxis: String, CaseIterable, Identifiable {
        case chest = "Chest", shoulders = "Shoulders", triceps = "Triceps", back = "Back",
             biceps = "Biceps", forearms = "Forearms", abs = "Abs", hips = "Hips",
             quadriceps = "Quadriceps", hamstrings = "Hamstrings", glutes = "Glutes", calves = "Calves"
        var id: String { rawValue }
    }

    var radarAxis: RadarAxis? {
        switch self {
        case .chest: .chest
        case .shoulders: .shoulders
        case .triceps: .triceps
        case .upperBack, .lats, .traps, .lowerBack: .back
        case .biceps: .biceps
        case .forearms: .forearms
        case .abdominals: .abs
        case .abductors, .adductors: .hips
        case .quadriceps: .quadriceps
        case .hamstrings: .hamstrings
        case .glutes: .glutes
        case .calves: .calves
        case .neck, .cardio, .fullBody, .other: nil
        }
    }
}
