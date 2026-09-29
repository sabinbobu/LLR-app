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
        KinetoLevelsSection(levels: $draft.kinetoLevels)
        Section {
            RestTimerPicker(selection: $draft.restSeconds)
        }
        Section("Notes") {
            TextField("Common mistakes", text: $draft.kinetoMistakes, axis: .vertical)
            TextField("Cautions", text: $draft.kinetoCautions, axis: .vertical)
        }
    }
}
