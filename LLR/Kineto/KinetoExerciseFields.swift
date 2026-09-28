import SwiftUI

struct KinetoExerciseFields: View {
    @Binding var draft: CustomExerciseDraft

    var body: some View {
        Section {
            Picker("Category", selection: $draft.kinetoCategory) {
                ForEach(KinetoCatalog.Category.allCases) { Text($0.title).tag($0) }
            }
            Picker("Direction", selection: $draft.kinetoDirection) {
                ForEach([KinetoCatalog.Direction.flexion, .extension, .rotation, .neutral], id: \.self) {
                    Text($0.title).tag($0)
                }
            }
        } footer: {
            Text("Direction drives the warning shown when it's the opposite of what your physiotherapist found helpful.")
        }
        Section {
            numberField("Sets", value: $draft.kinetoSets)
            numberField("Reps", value: $draft.kinetoReps)
            numberField("Hold (seconds)", value: $draft.kinetoDurationSeconds)
        } header: {
            Text("Dose")
        } footer: {
            Text("Leave a field empty if it doesn't apply, e.g. no reps for a timed hold.")
        }
        Section("Notes") {
            TextField("Common mistakes", text: $draft.kinetoMistakes, axis: .vertical)
            TextField("Cautions", text: $draft.kinetoCautions, axis: .vertical)
        }
    }

    private func numberField(_ title: String, value: Binding<Int?>) -> some View {
        LabeledContent(title) {
            TextField("—", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        }
    }
}
