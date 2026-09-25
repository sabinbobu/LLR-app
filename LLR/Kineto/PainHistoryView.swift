import Charts
import SwiftData
import SwiftUI

/// Back and leg pain, before and after, across Kineto sessions. A flagged session (≥ 2-point
/// rise, Ostelo 2008, or symptoms spread) is marked — the app surfaces it and stops there; only
/// the physiotherapist decides what changes next.
struct PainHistoryView: View {
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil && $0.sectionRaw == "kineto" }, sort: \Workout.startedAt)
    private var sessions: [Workout]
    @State private var region: Region = .back

    private enum Region: String, CaseIterable, Identifiable {
        case back = "Back", leg = "Leg"
        var id: String { rawValue }
    }

    private struct Point: Identifiable {
        let id = UUID()
        let date: Date
        let value: Int
        let stage: String
    }

    private func points(for region: Region) -> [Point] {
        sessions.flatMap { workout -> [Point] in
            let before = region == .back ? workout.backPainBefore : workout.legPainBefore
            let after = region == .back ? workout.backPainAfter : workout.legPainAfter
            var points: [Point] = []
            if let before { points.append(Point(date: workout.startedAt, value: before, stage: "Before")) }
            if let after { points.append(Point(date: workout.startedAt, value: after, stage: "After")) }
            return points
        }
    }

    private func isFlagged(_ workout: Workout) -> Bool {
        KinetoPain.shouldFlag(
            backBefore: workout.backPainBefore, backAfter: workout.backPainAfter,
            legBefore: workout.legPainBefore, legAfter: workout.legPainAfter,
            symptomsSpread: workout.symptomsSpread
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if sessions.isEmpty {
                    EmptyStateCard(systemImage: "chart.xyaxis.line", message: "Pain you log at check-in and check-out shows up here")
                } else {
                    Picker("Region", selection: $region) {
                        ForEach(Region.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    chart
                    sessionList
                }
            }
            .padding(16)
        }
        .background(Theme.background)
        .navigationTitle("Pain History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var chart: some View {
        Chart(points(for: region)) { point in
            LineMark(x: .value("Date", point.date), y: .value("Pain", point.value))
                .foregroundStyle(by: .value("Stage", point.stage))
            PointMark(x: .value("Date", point.date), y: .value("Pain", point.value))
                .foregroundStyle(by: .value("Stage", point.stage))
        }
        .chartYScale(domain: 0...10)
        .frame(height: 200)
        .padding()
        .cardStyle()
    }

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sessions").sectionLabel()
            ForEach(sessions.reversed(), id: \.id) { workout in
                sessionRow(workout)
            }
        }
    }

    private func sessionRow(_ workout: Workout) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.startedAt.formatted(date: .abbreviated, time: .omitted)).font(.subheadline.weight(.medium))
                Text("Back \(delta(workout.backPainBefore, workout.backPainAfter)) · Leg \(delta(workout.legPainBefore, workout.legPainAfter))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isFlagged(workout) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Flagged — discuss with your physio before progressing")
            }
        }
        .padding(12)
        .cardStyle(cornerRadius: 12)
    }

    private func delta(_ before: Int?, _ after: Int?) -> String {
        "\(before.map(String.init) ?? "–") → \(after.map(String.init) ?? "–")"
    }
}
