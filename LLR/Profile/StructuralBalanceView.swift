import SwiftData
import SwiftUI

struct StructuralBalanceView: View {
    let workouts: [Workout]
    @Query(filter: #Predicate<BodyMeasurement> { $0.kindRaw == "bodyWeight" }, sort: \BodyMeasurement.takenAt, order: .reverse)
    private var weighIns: [BodyMeasurement]
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @AppStorage(StorageKey.bodyWeightKg) private var onboardingWeightKg: Double = 0
    @State private var templateID = StructuralBalance.templates[0].id

    private var template: StructuralBalance.Template {
        StructuralBalance.templates.first { $0.id == templateID } ?? StructuralBalance.templates[0]
    }

    /// The latest weigh-in, else the weight given at onboarding.
    private var bodyweightKg: Double? {
        weighIns.first?.value ?? (onboardingWeightKg > 0 ? onboardingWeightKg : nil)
    }

    private var history: [String: [SetValue]] {
        var sets: [String: [SetValue]] = [:]
        for entry in workouts.flatMap(\.exercises) {
            guard let name = entry.exercise?.name else { continue }
            sets[name, default: []] += entry.completedSets.map(\.value)
        }
        return sets
    }

    var body: some View {
        let history = history
        List {
            Picker("Table", selection: $templateID) {
                ForEach(StructuralBalance.templates) { Text($0.title).tag($0.id) }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)

            ForEach(template.groups) { group in
                let result = StructuralBalance.evaluate(group, history: history, bodyweightKg: bodyweightKg)
                Section(group.title) {
                    referenceRow(result.reference)
                    ForEach(result.rows) { row in
                        StructuralBalanceRow(row: row, referenceName: group.reference.name, hasReference: result.reference.oneRepMaxKg != nil, unit: unit)
                    }
                }
            }

            Section("How this is read") {
                note("Each lift is your best estimated one-rep max from a working set, as a share of the reference lift. At or above the target is balanced; up to \(Int(StructuralBalance.borderlineBand)) points under is borderline. Dips and chin-ups count your body weight plus the load.")
                note(template.note)
                note("Source: \(template.citation)")
                if let url = template.url {
                    Link("Read the article", destination: url)
                        .font(.footnote)
                        .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Structural Balance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func referenceRow(_ row: StructuralBalance.Row) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.lift.name)
                Text("Reference lift").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(row.oneRepMaxKg.map { "\(unit.format(kg: $0)) \(unit.rawValue)" } ?? "Not logged yet")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(row.oneRepMaxKg == nil ? Color.secondary : Color.primary)
        }
        .padding(.vertical, 2)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .listRowSeparator(.hidden)
    }
}
