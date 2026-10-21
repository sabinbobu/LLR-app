import SwiftUI

struct WorkoutCard: View {
    let workout: Workout
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @State private var expanded = false

    var body: some View {
        let rows = workout.cardRows
        // The preview skips warm-ups so it shows real work; expanded shows the whole session in order.
        let preview = Array(rows.filter { !$0.isWarmup }.prefix(HomeModel.previewCount))
        let hidden = rows.count - preview.count
        VStack(alignment: .leading, spacing: 16) {
            header
            chips
            stats
            exercises(expanded ? rows : preview, hidden: hidden)
        }
        .surfaceCard()
        .contentShape(Rectangle())
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title).font(.title3.weight(.semibold))
                Text(workout.startedAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) + " · "
                    + workout.startedAt.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            // The button is 44 pt for the tap, pulled into the card's corner so it does not add height.
            WorkoutMenuButton(workout: workout)
                .padding(.top, -10)
                .padding(.trailing, -10)
        }
    }

    @ViewBuilder private var chips: some View {
        let records = workout.recordSetCount
        let muscles = workout.cardMuscles
        if workout.category != .none || records > 0 || !muscles.isEmpty {
            FlowLayout(spacing: 8) {
                if workout.category != .none { CategoryChip(category: workout.category) }
                if records > 0 {
                    Label("\(records) PR\(records == 1 ? "" : "s")", systemImage: "trophy.fill")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12).frame(height: 28)
                        .background(Theme.accent.opacity(0.15), in: Capsule())
                        .foregroundStyle(Theme.accent)
                }
                ForEach(muscles, id: \.self) { muscle in
                    Text(muscle)
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12).frame(height: 28)
                        .background(Theme.field, in: Capsule())
                        .foregroundStyle(Color.primary.opacity(0.8))
                }
            }
        }
    }

    private var stats: some View {
        HStack(spacing: 8) {
            StatTile(label: "Time", value: Format.duration(workout.duration))
            StatTile(label: "Volume", value: unit.fromKg(workout.volumeKg).formatted(.number.precision(.fractionLength(0...1))), unit: unit.rawValue)
            StatTile(label: "Sets", value: "\(workout.completedSets.count)")
        }
    }

    private func exercises(_ shown: [WorkoutCardRow], hidden: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exercises")
                .font(.footnote.weight(.semibold))
                .tracking(0.4)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            ForEach(shown) { row in
                (Text(row.name) + Text(" · \(row.sets)×").foregroundStyle(.secondary))
                    .font(.subheadline)
                    .foregroundStyle(row.isWarmup ? Color.secondary : Color.primary)
                    .lineLimit(2)
            }
            if hidden > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Text(expanded ? "Show less" : "+\(hidden) more")
                        Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption.weight(.bold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -8)
                .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            }
        }
    }
}

struct StatTile: View {
    let label: String
    let value: String
    var unit: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.title2.weight(.semibold).monospacedDigit())
                if !unit.isEmpty { Text(unit).font(.subheadline.weight(.medium)).foregroundStyle(.secondary) }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            Text(label).font(.footnote.weight(.medium)).foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.field, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
