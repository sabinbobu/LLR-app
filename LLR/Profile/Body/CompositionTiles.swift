import SwiftUI

struct CompositionTiles: View {
    let measurements: [BodyMeasurement]
    let trendWeightKg: Double?
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg

    private func latest(_ kind: MeasurementKind) -> Double? { BodyComposition.latest(kind, in: measurements)?.value }

    private var height: Double? { latest(.height) }
    private var weight: Double? { trendWeightKg ?? latest(.bodyWeight) }
    private var bodyFat: Double? { latest(.bodyFat) }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
            waistTile
            tile("Body fat", value: bodyFat.map { "\(Self.decimal($0, places: $0 == $0.rounded() ? 0 : 1))%" },
                 detail: "Latest logged", missing: "Log body fat", icon: "percent", color: Theme.fat)
            tile("Lean mass",
                 value: BodyComposition.leanMassKg(weightKg: weight, bodyFatPercent: bodyFat).map { "\(unit.format(kg: $0)) \(unit.rawValue)" },
                 detail: "Weight minus fat", missing: "Needs weight + body fat", icon: "figure.arms.open", color: Theme.protein)
            tile("BMI",
                 value: BodyComposition.bmi(weightKg: weight, heightCm: height).map { Self.decimal($0, places: 1) },
                 detail: "Misreads muscular builds", missing: "Needs weight + height", icon: "scalemass", color: .secondary)
        }
    }

    private var waistTile: some View {
        let ratio = BodyComposition.waistToHeight(waistCm: latest(.waist), heightCm: height)
        let zone = ratio.map(BodyComposition.zone(forWaistToHeight:))
        let color: Color = switch zone {
        case .healthy: .green
        case .increased: .orange
        case .high: .red
        case nil: .secondary
        }
        return tile("Waist ÷ height", value: ratio.map { Self.decimal($0, places: 2) },
                    detail: zone.map { "\($0.title) · aim under 0.50" } ?? "", missing: "Log waist to unlock",
                    icon: "ruler", color: color)
    }

    /// Fixed "." like `WeightUnit.format`, so one screen never mixes "24,9" with "67.7 kg".
    static func decimal(_ value: Double, places: Int) -> String { String(format: "%.\(places)f", value) }

    private func tile(_ title: String, value: String?, detail: String, missing: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            if let value {
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(detail).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            } else {
                Text("—").font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(.tertiary)
                Text(missing).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}
