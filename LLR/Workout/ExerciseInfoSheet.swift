import SwiftUI

/// The info page behind a logged or planned exercise.
struct ExerciseInfoSheet: View {
    let exercise: Exercise
    let isDurationBased: Bool

    var body: some View {
        NavigationStack {
            if let spec = exercise.customKinetoSpec {
                KinetoExerciseDetailView(exercise: spec, custom: exercise)
            } else if isDurationBased, let kinetoExercise = KinetoCatalog.exercise(named: exercise.name) {
                // A gym how-to can contradict a Kineto dose (Plank: "hold as long as possible"
                // vs. the catalog's 5 × 30 s), so a duration entry always shows its own page.
                KinetoExerciseDetailView(exercise: kinetoExercise)
            } else {
                ExerciseDetailView(exercise: exercise, showsDoneButton: true)
            }
        }
    }
}
