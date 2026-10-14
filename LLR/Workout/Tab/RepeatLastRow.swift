import SwiftUI

/// The last few finished workouts as one-tap chips. The full list, with long-press Repeat,
/// stays in history; ten rows here only pushed everything else off screen.
struct RepeatLastRow: View {
    let workouts: [Workout]
    let canStart: Bool
    let onRepeat: (Workout) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repeat last").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(workouts) { workout in
                        Button { onRepeat(workout) } label: {
                            Label(workout.title, systemImage: "arrow.counterclockwise")
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .foregroundStyle(Theme.repeatActionLabel)
                                .padding(.horizontal, 14)
                                .frame(height: 40)
                                .background(Theme.repeatAction, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(!canStart)
                        .opacity(canStart ? 1 : 0.4)
                    }
                }
            }
            .scrollClipDisabled()
            if !canStart {
                Text("Finish or resume your open workout to repeat another.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
