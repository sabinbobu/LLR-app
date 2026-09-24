import SwiftUI

struct ExerciseStepsView: View {
    let steps: [String]

    var body: some View {
        if steps.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(.tertiary)
                Text("No instructions").font(.headline)
                Text("This one has no step-by-step guide. Log it like any other exercise.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .cardStyle()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Steps").font(.footnote.weight(.semibold))
                    Spacer()
                    Text("^[\(steps.count) step](inflect: true)").font(.footnote)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        if index > 0 {
                            Divider().padding(.horizontal, 16)
                        }
                        row(number: index + 1, text: step)
                    }
                }
                .cardStyle()
            }
        }
    }

    private func row(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.footnote.bold())
                .foregroundStyle(Theme.accent)
                .frame(width: 26, height: 26)
                .background(Theme.accentSoft, in: Circle())
            Text(text)
                .font(.subheadline)
                .lineSpacing(3)
                .padding(.top, 3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(text)")
    }
}
