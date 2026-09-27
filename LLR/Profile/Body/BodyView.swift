import SwiftData
import SwiftUI

struct BodyView: View {
    @Query(sort: \BodyMeasurement.takenAt) private var measurements: [BodyMeasurement]
    @Query(sort: \ProgressPhoto.takenAt, order: .reverse) private var photos: [ProgressPhoto]
    @State private var loggingWeight = false
    @State private var opening: MeasurementKind?

    private var weighIns: [BodyMeasurement] { measurements.filter { $0.kind == .bodyWeight } }

    var body: some View {
        let trend = WeightTrend.points(weighIns.map { ($0.takenAt, $0.value) })
        ScrollView {
            VStack(spacing: 16) {
                WeightTrendCard(weighIns: weighIns) { loggingWeight = true }
                CompositionTiles(measurements: measurements, trendWeightKg: trend.last?.trend)
                TapeMeasurementsCard(measurements: measurements) { opening = $0 }
                PhotoStripCard(photos: photos, trend: trend)
                NavigationLink {
                    MeasurementsView()
                } label: {
                    HStack {
                        Label("All measurements", systemImage: "list.bullet")
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    .padding(18)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Body")
        .navigationDestination(item: $opening) { MeasurementDetailView(kind: $0) }
        .sheet(isPresented: $loggingWeight) {
            QuickLogSheet(kind: .bodyWeight, latestCanonical: weighIns.last?.value)
        }
    }
}
