import SwiftUI

struct RoutineHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CircleIconButton(systemName: "arrow.left") { dismiss() }
                Spacer()
                Text("Routine Help").font(.title2.weight(.medium))
                Spacer()
                Color.clear.frame(width: 48, height: 48)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            ScrollView {
                VStack(spacing: 40) {
                    step(
                        "Routines are reusable and save you time by letting you plan your workout before going to the gym.",
                        mockup: { RoutinePlanMockup(stage: .empty) }
                    )
                    step(
                        "Input your planned weight & reps for your routine ahead of time, or leave it blank to workout on the go.",
                        mockup: { RoutinePlanMockup(stage: .sets) }
                    )
                    step(
                        "Add notes per exercise to always have them handy during your workout.",
                        mockup: { RoutinePlanMockup(stage: .notes) }
                    )
                    step(
                        "Set automatic rest timers to have some rest time between sets.",
                        mockup: { RoutinePlanMockup(stage: .restTimer) }
                    )

                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.completedCheck)
                        Text("Finish creating your routine").font(.title3.weight(.medium))
                    }
                    .padding(.top, 8)

                    Button("Back") { dismiss() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func step(_ text: String, @ViewBuilder mockup: () -> some View) -> some View {
        VStack(spacing: 20) {
            Text(text)
                .font(.title3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            mockup()
                .padding(16)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.border, lineWidth: 1.5))
        }
    }
}
