import SwiftUI

struct GymExerciseFields: View {
    @Binding var draft: CustomExerciseDraft

    var body: some View {
        Section {
            NavigationLink {
                MultiSelectList(
                    title: "Secondary muscles",
                    options: MuscleGroup.allCases.map(\.rawValue).filter { $0 != draft.muscleGroup },
                    selection: $draft.secondaryMuscles
                )
            } label: {
                LabeledContent("Secondary muscles", value: summary(draft.secondaryMuscles.filter { $0 != draft.muscleGroup }))
            }
            NavigationLink {
                MultiSelectList(title: "Equipment", options: Equipment.choices, selection: $draft.equipment)
            } label: {
                LabeledContent("Equipment", value: Equipment.label(draft.equipment))
            }
        } footer: {
            Text("Secondary muscles count as half a set toward weekly volume.")
        }
        Section {
            Picker("Rest timer", selection: $draft.restSeconds) {
                Text("Default").tag(Int?.none)
                ForEach(RestDuration.choices, id: \.self) { Text(RestDuration.label($0)).tag(Int?.some($0)) }
                Text("Off").tag(Int?.some(0))
            }
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

    private func summary(_ values: [String]) -> String {
        values.isEmpty ? "None" : values.joined(separator: ", ")
    }
}
