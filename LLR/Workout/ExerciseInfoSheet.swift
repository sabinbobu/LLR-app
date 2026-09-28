import SwiftUI

/// The info page behind a logged or planned exercise.
struct ExerciseInfoSheet: View {
    let exercise: Exercise
    let section: WorkoutSection
    let isDurationBased: Bool

    var body: some View {
        NavigationStack {
            if let spec = exercise.customKinetoSpec {
                KinetoExerciseDetailView(exercise: spec, row: exercise)
            } else if section == .kineto || isDurationBased, let kinetoExercise = KinetoCatalog.exercise(named: exercise.name) {
                // A gym how-to can contradict a Kineto dose (Plank: "hold as long as possible"
                // vs. the catalog's 5 × 30 s), so a Kineto or duration entry shows its own page.
                KinetoExerciseDetailView(exercise: kinetoExercise, row: exercise)
            } else {
                ExerciseDetailView(exercise: exercise, showsDoneButton: true)
            }
        }
    }
}
