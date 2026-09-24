import SwiftUI

struct ExerciseOverviewCard: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview").sectionLabel()
            VStack(spacing: 0) {
                muscles("Primary muscle", [exercise.muscleGroup], prominent: true)
                if !exercise.secondaryMuscles.isEmpty {
                    Divider().padding(.horizontal, 16)
                    muscles("Secondary muscles", exercise.secondaryMuscles, prominent: false)
                }
                Divider().padding(.horizontal, 16)
                equipmentRow
            }
            .cardStyle()
        }
    }

    private func muscles(_ title: String, _ names: [String], prominent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.5)
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 8) {
                ForEach(names, id: \.self) { name in
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(prominent ? Color.white : Theme.accent)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(prominent ? Theme.accent : Theme.accentSoft, in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }

    private var equipmentRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(Theme.field, in: RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            Text("Equipment").foregroundStyle(.secondary)
            Spacer()
            Text(Equipment.label(exercise.equipment)).fontWeight(.semibold)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
