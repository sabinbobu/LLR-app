import SwiftUI

struct GymExerciseFields: View {
    @Binding var draft: CustomExerciseDraft

    var body: some View {
        Section {
            RestTimerPicker(selection: $draft.restSeconds)
            Picker("Rep range", selection: $draft.repRange) {
                Text("Off").tag(ClosedRange<Int>?.none)
                ForEach(Progression.presets, id: \.self) { range in
                    Text("\(range.lowerBound)–\(range.upperBound) reps").tag(ClosedRange<Int>?.some(range))
                }
            }
        } footer: {
            Text("With a rep range set, the next session aims for one more rep, and adds weight once every set reached the top.")
        }
    }
}
