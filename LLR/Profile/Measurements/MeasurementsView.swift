import SwiftData
import SwiftUI

struct MeasurementsView: View {
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @Query(sort: \BodyMeasurement.takenAt, order: .reverse) private var measurements: [BodyMeasurement]
    @Query(sort: \ProgressPhoto.takenAt, order: .reverse) private var photos: [ProgressPhoto]

    /// Most recent entry per kind, from an already-descending query — first match wins.
    private func latest(_ kind: MeasurementKind) -> BodyMeasurement? {
        measurements.first { $0.kind == kind }
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ProgressPhotosView()
                } label: {
                    HStack {
                        Image(systemName: "camera").frame(width: 28)
                        VStack(alignment: .leading) {
                            Text("Progress Photos")
                            Text(photos.isEmpty ? "Add Photo" : "\(photos.count) photo\(photos.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("My Measurements") {
                ForEach(MeasurementKind.allCases) { kind in
                    NavigationLink {
                        MeasurementDetailView(kind: kind)
                    } label: {
                        row(kind)
                    }
                }
            }
        }
        .navigationTitle("Measurements")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ kind: MeasurementKind) -> some View {
        HStack {
            Image(systemName: kind.systemImage).frame(width: 28)
            VStack(alignment: .leading) {
                Text(kind.title)
                if let entry = latest(kind) {
                    Text(kind.format(entry.value, unit: unit))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Add Measurement")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
