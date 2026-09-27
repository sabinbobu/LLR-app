import SwiftData
import SwiftUI

struct AddMeasurementSheet: View {
    let kind: MeasurementKind
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var date = Date.now

    private var suffix: String {
        switch kind.dimension {
        case .mass: unit.rawValue
        case .length: unit.lengthSuffix
        case .percent: "%"
        }
    }

    private var value: Double? { WeightUnit.parse(text) }

    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    TextField("Value", text: $text)
                        .keyboardType(.decimalPad)
                    Text(suffix).foregroundStyle(.secondary)
                }
                DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(value == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        guard let entered = value else { return }
        let canonical: Double = switch kind.dimension {
        case .mass: unit.toKg(entered)
        case .length: unit.toCm(entered)
        case .percent: entered
        }
        context.insert(BodyMeasurement(kind: kind, value: canonical, takenAt: date))
        dismiss()
    }
}
