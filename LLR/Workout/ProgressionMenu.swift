import SwiftUI

/// The rule that sets this exercise's next targets, and the reason behind the current ones.
struct ProgressionMenu: View {
    let entry: WorkoutExercise
    let exercise: Exercise
    let model: ActiveWorkoutModel
    let unit: WeightUnit

    var body: some View {
        let config = exercise.progression(unit: unit)
        VStack(alignment: .leading, spacing: 4) {
            Menu {
                Button("Off") { model.setProgression(nil, range: nil, for: entry) }
                if entry.isDurationBased {
                    Button("Add \(Progression.holdStepSeconds) s Each Session") { model.setProgression(.time, range: nil, for: entry) }
                } else {
                    rules
                    if config != nil { stepMenu }
                }
            } label: {
                Label("Progression: \(Progression.title(config))", systemImage: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Theme.accent)
            }
            if let config {
                Text(Progression.why(Progression.plan(history: model.history(for: exercise), config: config), config: config, unit: unit))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var rules: some View {
        Menu("Double Progression") {
            ForEach(Progression.presets, id: \.self) { preset in
                Button("\(preset.lowerBound)–\(preset.upperBound) reps") { model.setProgression(.double, range: preset, for: entry) }
            }
        }
        Menu("Linear") {
            ForEach(Progression.fixedReps, id: \.self) { reps in
                Button("\(reps) reps") { model.setProgression(.linear, range: reps...reps, for: entry) }
            }
        }
        Button("Greyskull LP") {
            model.setProgression(.greyskull, range: Progression.greyskullReps...Progression.greyskullReps, for: entry)
        }
    }

    private var stepMenu: some View {
        let automatic = Progression.incrementKg(equipment: exercise.equipment, unit: unit)
        return Menu("Step: \(unit.format(kg: exercise.progressionStepKg ?? automatic)) \(unit.rawValue)") {
            Button("Automatic (\(unit.format(kg: automatic)) \(unit.rawValue))") { model.setProgressionStep(nil, for: entry) }
            ForEach(Progression.stepChoicesKg(unit: unit), id: \.self) { step in
                Button("\(unit.format(kg: step)) \(unit.rawValue)") { model.setProgressionStep(step, for: entry) }
            }
        }
    }
}
