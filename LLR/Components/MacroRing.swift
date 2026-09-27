import SwiftUI

/// Calories eaten against the target. Past 100% a second, red lap draws over the first, so
/// "over" reads at a glance instead of the ring just sitting full.
struct MacroRing: View {
    let value: Double
    let target: Double
    var lineWidth: CGFloat = 18

    private var progress: Double { DailyNutrition.progress(value, of: target) }
    private var remaining: Double { target - value }

    var body: some View {
        ZStack {
            Circle().stroke(Theme.kcal.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(AngularGradient(colors: [Theme.kcal.opacity(0.7), Theme.kcal], center: .center),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if progress > 1 {
                Circle()
                    .trim(from: 0, to: min(progress - 1, 1))
                    .stroke(Theme.over, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 2) {
                Text(abs(remaining).formatted(.number.precision(.fractionLength(0))))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(remaining >= 0 ? "kcal left" : "kcal over")
                    .font(.subheadline)
                    .foregroundStyle(remaining >= 0 ? Color.secondary : Theme.over)
                Text("\(Int(value)) / \(Int(target))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(lineWidth / 2)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: target)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Calories \(Int(value)) of \(Int(target))")
    }
}
