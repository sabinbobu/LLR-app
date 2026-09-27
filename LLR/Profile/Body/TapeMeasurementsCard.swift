import Charts
import SwiftUI

/// Tape sites on the body itself: tap where you measured instead of hunting a 13-row list.
struct TapeMeasurementsCard: View {
    let measurements: [BodyMeasurement]
    let onOpen: (MeasurementKind) -> Void
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg

    static let sites: [MeasurementKind] = [
        .neck, .shoulders, .chest, .waist, .hips, .leftBicep, .rightBicep,
        .leftForearm, .rightForearm, .leftThigh, .rightThigh, .leftCalf, .rightCalf,
    ]

    private func history(_ kind: MeasurementKind) -> [BodyMeasurement] {
        measurements.filter { $0.kind == kind }.sorted { $0.takenAt < $1.takenAt }
    }

    /// Change over the last 30 days; nil with fewer than two entries in reach.
    private func change(_ kind: MeasurementKind) -> Double? {
        let entries = history(kind)
        guard let last = entries.last, let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: last.takenAt),
              let base = entries.last(where: { $0.takenAt <= cutoff }) ?? entries.first, base !== last else { return nil }
        return last.value - base.value
    }

    private var measuredGroups: Set<MuscleGroup> {
        Set(Self.sites.filter { !history($0).isEmpty }.compactMap(\.muscle)
            + (history(.waist).isEmpty ? [] : [.abdominals]) + (history(.hips).isEmpty ? [] : [.glutes]))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Tape measurements").font(.headline)
                Spacer()
                Text("Tap the body").font(.caption).foregroundStyle(.secondary)
            }
            BodyMapView(tint: { groups in
                groups.contains(where: measuredGroups.contains) ? Theme.accent.opacity(0.75) : nil
            }, onTap: { side, point in
                if let kind = BodyMapHitTest.measurement(at: point, side: side) { onOpen(kind) }
            })
            .frame(height: 230)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)

            let logged = Self.sites.filter { !history($0).isEmpty }
            if logged.isEmpty {
                Text("No tape measurements yet. Tap a muscle above to log your first one.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                ForEach(logged) { kind in
                    Button { onOpen(kind) } label: { row(kind) }.buttonStyle(.plain)
                    if kind != logged.last { Divider() }
                }
            }
        }
        .padding(20)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private func row(_ kind: MeasurementKind) -> some View {
        let entries = history(kind)
        return HStack(spacing: 12) {
            Text(kind.title).frame(maxWidth: .infinity, alignment: .leading)
            if entries.count > 1 {
                Chart(entries) { LineMark(x: .value("Date", $0.takenAt), y: .value("Value", $0.value)).interpolationMethod(.catmullRom) }
                    .chartXAxis(.hidden).chartYAxis(.hidden)
                    .chartYScale(domain: .automatic(includesZero: false))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 60, height: 24)
            }
            VStack(alignment: .trailing, spacing: 1) {
                Text(entries.last.map { kind.format($0.value, unit: unit) } ?? "")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                if let delta = change(kind), abs(delta) >= 0.1 {
                    Text("\(delta > 0 ? "+" : "−")\(unit.formatLength(cm: abs(delta))) \(unit.lengthSuffix) · 30d")
                        .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                }
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}
