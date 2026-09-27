import Charts
import SwiftData
import SwiftUI

struct MeasurementDetailView: View {
    let kind: MeasurementKind
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false
    @State private var range: TrendRange = .all

    @Query private var entries: [BodyMeasurement]

    init(kind: MeasurementKind) {
        self.kind = kind
        let raw = kind.rawValue
        _entries = Query(filter: #Predicate<BodyMeasurement> { $0.kindRaw == raw }, sort: \BodyMeasurement.takenAt)
    }

    private var newestFirst: [BodyMeasurement] { entries.reversed() }

    private var visible: [BodyMeasurement] {
        guard let start = range.start() else { return entries }
        return entries.filter { $0.takenAt >= start }
    }

    /// Only bodyweight fluctuates enough day to day to need smoothing; tape sites plot as logged.
    private var trend: [WeightTrend.Point] {
        guard kind == .bodyWeight else { return [] }
        let start = range.start() ?? .distantPast
        return WeightTrend.points(entries.map { ($0.takenAt, $0.value) }).filter { $0.date >= start }
    }

    var body: some View {
        List {
            if entries.count > 1 {
                Section {
                    chart
                    Picker("Range", selection: $range) {
                        ForEach(TrendRange.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .sensoryFeedback(.selection, trigger: range)
                }
                .listRowSeparator(.hidden)
            }
            Section {
                ForEach(newestFirst) { entry in
                    HStack {
                        Text(entry.takenAt.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text(kind.format(entry.value, unit: unit)).monospacedDigit().foregroundStyle(.secondary)
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
            QuickLogSheet(kind: kind, latestCanonical: entries.last?.value)
        }
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView {
                    Label("No \(kind.title.lowercased()) yet", systemImage: kind.systemImage)
                } actions: {
                    Button("Log \(kind.title.lowercased())") { showingAdd = true }.buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(visible) { entry in
                PointMark(x: .value("Date", entry.takenAt), y: .value(kind.title, displayValue(entry.value)))
                    .symbolSize(kind == .bodyWeight ? 18 : 36)
                    .foregroundStyle(Theme.accent.opacity(kind == .bodyWeight ? 0.3 : 1))
                if kind != .bodyWeight {
                    LineMark(x: .value("Date", entry.takenAt), y: .value(kind.title, displayValue(entry.value)))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.accent)
                }
            }
            ForEach(trend, id: \.date) { point in
                LineMark(x: .value("Date", point.date), y: .value("Trend", displayValue(point.trend)))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .foregroundStyle(Theme.accent)
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: 200)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: range)
    }

    private func displayValue(_ canonical: Double) -> Double {
        switch kind.dimension {
        case .mass: unit.fromKg(canonical)
        case .length: unit.fromCm(canonical)
        case .percent: canonical
        }
    }
}
