import SwiftUI

/// Grams eaten against a target. The track represents 125% of target so there's room to show
/// the overshoot as its own red segment, with a tick marking exactly 100%.
struct MacroBar: View {
    let title: String
    let value: Double
    let target: Double
    let color: Color

    private static let trackSpan = 1.25
    private var progress: Double { DailyNutrition.progress(value, of: target) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(value.rounded()))")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .contentTransition(.numericText())
                Text("/ \(Int(target.rounded())) g")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                let unit = geo.size.width / Self.trackSpan
                let filled = min(progress, 1)
                let over = min(max(progress - 1, 0), Self.trackSpan - 1)
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.15))
                    Capsule()
                        .fill(LinearGradient(colors: [color.opacity(0.75), color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(unit * filled, progress > 0 ? 10 : 0))
                    if over > 0 {
                        Capsule()
                            .fill(Theme.over)
                            .frame(width: unit * over)
                            .offset(x: unit)
                    }
                    Rectangle()
                        .fill(Color.primary.opacity(0.35))
                        .frame(width: 2)
                        .offset(x: unit - 1)
                }
            }
            .frame(height: 12)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(Int(value)) of \(Int(target)) grams")
    }
}
