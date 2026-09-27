import SwiftUI

struct WeeklyVolumeView: View {
    let entries: [MuscleRecovery.Entry]
    @State private var weeksBack = 0
    @State private var showingInfo = false

    private static let maxWeeksBack = 11
    // Past 25 the bar would just be "a lot"; capping keeps the 10–20 zone wide enough to read.
    private static let scaleMax = 25.0

    private var week: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: -weeksBack, to: .now) ?? .now
    }

    private var sets: [MuscleGroup.RadarAxis: Double] { WeeklyVolume.sets(entries, week: week) }

    private var weekTitle: String {
        switch weeksBack {
        case 0: "This week"
        case 1: "Last week"
        default:
            Calendar.current.dateInterval(of: .weekOfYear, for: week)?.start
                .formatted(.dateTime.month(.abbreviated).day()).appending(" week") ?? ""
        }
    }

    var body: some View {
        let sets = sets
        List {
            Section {
                weekStepper
                let inRange = MuscleGroup.RadarAxis.allCases.filter { WeeklyVolume.band(for: sets[$0] ?? 0) == .target }.count
                Text("\(inRange) of \(MuscleGroup.RadarAxis.allCases.count) muscles in range")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
            }
            if sets.isEmpty {
                EmptyStateCard(systemImage: "chart.bar.xaxis", message: "No working sets this week")
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            } else {
                Section("Hard sets") {
                    ForEach(MuscleGroup.RadarAxis.allCases) { axis in
                        row(axis, sets: sets[axis] ?? 0)
                    }
                }
            }
        }
        .navigationTitle("Weekly Volume")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingInfo = true
            } label: {
                Image(systemName: "info.circle")
            }
        }
        .sheet(isPresented: $showingInfo) { infoSheet }
    }

    private var weekStepper: some View {
        HStack {
            Button {
                weeksBack += 1
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(weeksBack >= Self.maxWeeksBack)
            Spacer()
            Text(weekTitle).font(.subheadline.weight(.semibold))
            Spacer()
            Button {
                weeksBack -= 1
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(weeksBack == 0)
        }
        .buttonStyle(.borderless)
    }

    private func row(_ axis: MuscleGroup.RadarAxis, sets: Double) -> some View {
        let band = WeeklyVolume.band(for: sets)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(axis.rawValue)
                Spacer()
                Text(sets.formatted(.number.precision(.fractionLength(0...1))))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                Text(Self.label(band))
                    .font(.caption)
                    .foregroundStyle(Self.color(band))
                    .frame(width: 64, alignment: .trailing)
            }
            GeometryReader { geo in
                let unit = geo.size.width / Self.scaleMax
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Rectangle()
                        .fill(Color.green.opacity(0.18))
                        .frame(width: unit * (WeeklyVolume.targetRange.upperBound - WeeklyVolume.targetRange.lowerBound))
                        .offset(x: unit * WeeklyVolume.targetRange.lowerBound)
                    Capsule()
                        .fill(Self.color(band))
                        .frame(width: unit * min(sets, Self.scaleMax))
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }

    private static func label(_ band: WeeklyVolume.Band) -> String {
        switch band {
        case .none: "None"
        case .low: "Low"
        case .building: "Building"
        case .target: "In range"
        case .high: "High"
        }
    }

    private static func color(_ band: WeeklyVolume.Band) -> Color {
        switch band {
        case .none, .low: .red
        case .building: .orange
        case .target: .green
        case .high: Theme.accent
        }
    }

    private var infoSheet: some View {
        NavigationStack {
            ScrollView {
                Text("""
                Counts your working sets per muscle this week. Warm-ups don't count. A muscle an \
                exercise mainly targets gets a full set; one it only assists with gets half.

                The shaded zone is 10–20 sets. Research pooling many training studies found muscles \
                grew more from about 10+ weekly sets than from under 5, with diminishing returns as \
                volume climbs. Above 20 isn't wrong, but recovery usually becomes the limit.

                Sources: Schoenfeld, Ogborn & Krieger (2017), J Sports Sci; \
                Pelland et al. (2025), Sports Med.
                """)
                .padding()
            }
            .navigationTitle("About Weekly Volume")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { showingInfo = false }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
