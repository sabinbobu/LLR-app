import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: String
    var isCustom: Bool
    /// nil = use the global default; 0 = no rest timer for this exercise.
    var restSeconds: Int?
    // Library metadata; defaults let existing stores migrate without a schema version bump.
    var equipment: [String] = []
    var secondaryMuscles: [String] = []
    var instructions: [String] = []
    /// Opt-in progression range; nil = prefill last session's values unchanged.
    var repRangeMin: Int?
    var repRangeMax: Int?
    /// "" = automatic: double progression whenever a rep range is set, as it was before rules existed.
    var progressionRuleRaw: String = ""
    /// nil = the smallest step the kit usually offers.
    var progressionStepKg: Double?
    /// Which picker a custom exercise lives in. Built-ins stay "gym": Kineto's own entries resolve
    /// through `KinetoCatalog` by name, so only user-made Kineto exercises need this.
    var sectionRaw: String = "gym"
    // A user-made Kineto exercise's fields; the bundled catalog keeps its own in JSON.
    var kinetoCategoryRaw: String?
    var kinetoDirectionRaw: String?
    /// The single dose rows had before levels existed; only read while `kinetoLevelsData` is nil.
    var kinetoSets: Int?
    var kinetoReps: Int?
    var kinetoDurationSeconds: Int?
    var kinetoMistakes: String?
    var kinetoCautions: String?
    // JSON lists of small structs nothing ever queries into; see `kinetoLevels` / `kinetoSources`.
    var kinetoLevelsData: Data?
    var kinetoSourcesData: Data?
    /// Your own cues on any exercise, e.g. what your physiotherapist corrected. Library sync never touches it.
    var personalNotes: String = ""
    /// A personal shortlist that floats to the top of lists. Library sync never touches it.
    var isFavourite: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \ExerciseMedia.exercise) var media: [ExerciseMedia] = []
    @Relationship(inverse: \WorkoutExercise.exercise) var usages: [WorkoutExercise] = []

    init(name: String, muscleGroup: String, isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.isCustom = isCustom
    }
}

/// Kineto is a physiotherapist-gated back-care section, kept out of gym history and stats. Stored
/// (not derived) so it can be used in a `#Predicate`, and named unlike `SetEntry.kindRaw`/`SetKind`
/// on purpose so the two are never confused.
enum WorkoutSection: String {
    case gym, kineto
}
