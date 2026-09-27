import Charts
import SwiftUI

enum TrendRange: String, CaseIterable, Identifiable {
    case month = "1M", quarter = "3M", half = "6M", year = "1Y", all = "All"
    var id: String { rawValue }

    func start(now: Date = .now) -> Date? {
        let months: Int? = switch self {
        case .month: 1
        case .quarter: 3
        case .half: 6
        case .year: 12
        case .all: nil
        }
        return months.flatMap { Calendar.current.date(byAdding: .month, value: -$0, to: now) }
    }
}

struct WeightTrendCard: View {
    let weighIns: [BodyMeasurement]
    let onLog: () -> Void
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @State private var range: TrendRange = .quarter

    private var points: [WeightTrend.Point] {
        WeightTrend.points(weighIns.map { ($0.takenAt, $0.value) })
    }

    private var visible: [WeightTrend.Point] {
        guard let start = range.start() else { return points }
        return points.filter { $0.date >= start }
    }

    var body: some View {
        let points = points
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trend weight").font(.subheadline).foregroundStyle(.secondary)
                    if let latest = points.last {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(unit.format(kg: latest.trend))
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                            Text(unit.rawValue).font(.title3).foregroundStyle(.secondary)
                        }
                    } else {
                        Text("—").font(.system(size: 44, weight: .bold, design: .rounded))
                    }
                }
                Spacer()
                Button(action: onLog) {
                    Label("Log", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(Theme.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            HStack(spacing: 10) {
                if let rate = WeightTrend.weeklyRate(points) {
                    chip(delta: rate, suffix: "/wk")
                }
                if let start = range.start() ?? points.first?.date, let change = WeightTrend.change(points, since: start) {
                    chip(delta: change, suffix: " in \(range == .all ? "total" : range.rawValue)")
                }
            }
            if weighIns.count >= 3 {
                chart
                Picker("Range", selection: $range) {
                    ForEach(TrendRange.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .sensoryFeedback(.selection, trigger: range)
            } else {
                Text("Weigh in \(3 - weighIns.count) more time\(3 - weighIns.count == 1 ? "" : "s") to see your trend. Daily scale weight swings with water and food; the trend shows what's really changing.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private var chart: some View {
        Chart(visible, id: \.date) { point in
            if let raw = point.raw {
                PointMark(x: .value("Date", point.date), y: .value("Weight", unit.fromKg(raw)))
                    .symbolSize(18)
                    .foregroundStyle(Theme.accent.opacity(0.3))
            }
            LineMark(x: .value("Date", point.date), y: .value("Trend", unit.fromKg(point.trend)))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .foregroundStyle(Theme.accent)
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
        .frame(height: 170)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: range)
    }

    private func chip(delta: Double, suffix: String) -> some View {
        let display = unit.fromKg(abs(delta))
        let flat = display < 0.05
        return Label {
            Text("\(flat ? "±" : delta < 0 ? "−" : "+")\(CompositionTiles.decimal(display, places: 1)) \(unit.rawValue)\(suffix)")
        } icon: {
            Image(systemName: flat ? "equal" : delta < 0 ? "arrow.down.right" : "arrow.up.right")
        }
        .font(.caption.weight(.semibold).monospacedDigit())
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Theme.field, in: Capsule())
    }
}
