import Charts
import SwiftData
import SwiftUI

struct MeasurementDetailView: View {
    let kind: MeasurementKind
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false

    @Query private var entries: [BodyMeasurement]

    init(kind: MeasurementKind) {
        self.kind = kind
        let raw = kind.rawValue
        _entries = Query(filter: #Predicate<BodyMeasurement> { $0.kindRaw == raw }, sort: \BodyMeasurement.takenAt)
    }

    private var newestFirst: [BodyMeasurement] { entries.reversed() }

    var body: some View {
        List {
            if entries.count > 1 {
                Section {
                    Chart(entries) { entry in
                        LineMark(x: .value("Date", entry.takenAt), y: .value(kind.title, displayValue(entry.value)))
                        PointMark(x: .value("Date", entry.takenAt), y: .value(kind.title, displayValue(entry.value)))
                    }
                    .foregroundStyle(Theme.accent)
                    .frame(height: 180)
                }
                .listRowSeparator(.hidden)
            }
            Section {
                ForEach(newestFirst) { entry in
                    HStack {
                        Text(entry.takenAt.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text(kind.format(entry.value, unit: unit)).foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in offsets.forEach { context.delete(newestFirst[$0]) } }
            }
        }
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingAdd = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddMeasurementSheet(kind: kind)
        }
        .overlay {
            if entries.isEmpty {
                EmptyStateCard(systemImage: kind.systemImage, message: "No measurements yet")
            }
        }
    }

    private func displayValue(_ canonical: Double) -> Double {
        switch kind.dimension {
        case .mass: unit.fromKg(canonical)
        case .length: unit.fromCm(canonical)
        case .percent: canonical
        }
    }
}
