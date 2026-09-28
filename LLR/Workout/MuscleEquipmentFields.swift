import SwiftUI

/// Secondary muscles and equipment, which gym and Kineto exercises both carry.
struct MuscleEquipmentFields: View {
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
            // Kineto sessions are kept out of stats, so the volume note would be wrong there.
            if draft.section == .gym {
                Text("Secondary muscles count as half a set toward weekly volume.")
            }
        }
    }

    private func summary(_ values: [String]) -> String {
        values.isEmpty ? "None" : values.joined(separator: ", ")
    }
}
