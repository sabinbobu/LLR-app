import SwiftUI

struct StructuralBalanceRow: View {
    let row: StructuralBalance.Row
    let referenceName: String
    let hasReference: Bool
    let unit: WeightUnit

    // The bar runs to 125% of the target, so the target tick sits at four fifths of its width.
    private static let scale = 1.25

    private var detail: String {
        let target = "Target \(Self.percent(row.lift.targetPct)) of \(referenceName)"
        if let kg = row.oneRepMaxKg {
            let lifted = "\(unit.format(kg: kg)) \(unit.rawValue)"
            return hasReference ? "\(lifted) · \(target)" : "\(lifted) · log \(referenceName) to score it"
        }
        if row.needsBodyweight { return "Log your body weight to score it" }
        return "Not logged yet · \(target)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.lift.name)
                Spacer()
                if let actual = row.actualPct {
                    Text(Self.percent(actual)).font(.subheadline.weight(.semibold).monospacedDigit())
                }
                Text(Self.label(row.status))
                    .font(.caption)
                    .foregroundStyle(Self.color(row.status))
                    .frame(width: 72, alignment: .trailing)
            }
            Text(detail).font(.caption).foregroundStyle(.secondary)
            GeometryReader { geo in
                let share = min((row.actualPct ?? 0) / row.lift.targetPct, Self.scale) / Self.scale
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule().fill(Self.color(row.status)).frame(width: geo.size.width * share)
                    Rectangle().fill(Color.primary.opacity(0.55)).frame(width: 2).offset(x: geo.size.width / Self.scale - 1)
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())
            .accessibilityHidden(true)
        }
        .padding(.vertical, 2)
    }

    /// `%.0f`, not `Int(_:)`: a near-zero reference lift makes the share huge enough to trap.
    private static func percent(_ value: Double) -> String { String(format: "%.0f%%", value.rounded()) }

    private static func label(_ status: StructuralBalance.Status) -> String {
        switch status {
        case .balanced: "Balanced"
        case .borderline: "Borderline"
        case .weak: "Weak"
        case .noData: "No data"
        }
    }

    private static func color(_ status: StructuralBalance.Status) -> Color {
        switch status {
        case .balanced: .green
        case .borderline: .orange
        case .weak: .red
        case .noData: .secondary
        }
    }
}
