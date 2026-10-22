import SwiftUI

struct WorkoutCard: View {
    let workout: Workout
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @State private var expanded = false

    var body: some View {
        let model = WorkoutCardModel(workout: workout)
        VStack(alignment: .leading, spacing: 16) {
            header
            if !model.chips.isEmpty { chips(model.chips) }
            stats
            exercises(model)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
        .contentShape(Rectangle())
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(workout.title).font(.title3.weight(.semibold))
                    CategoryChip(category: workout.category)
                }
                Text(dateLine).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            // Pulled into the card's padding so the 44 pt tap target doesn't push the title down.
            WorkoutMoreMenu(workout: workout).padding(.trailing, -10).padding(.top, -10)
        }
    }

    private var dateLine: String {
        let day = workout.startedAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        let time = workout.startedAt.formatted(date: .omitted, time: .shortened)
        let records = workout.recordSetCount
        return "\(day) · \(time)" + (records > 0 ? " · 🏆 \(records)" : "")
    }

    private func chips(_ names: [String]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(names, id: \.self) { name in
                Text(name)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .background(Theme.field, in: Capsule())
            }
        }
    }

    private var stats: some View {
        HStack(spacing: 8) {
            tile("Time", Format.duration(workout.duration))
            tile("Volume", unit.fromKg(workout.volumeKg).formatted(.number.precision(.fractionLength(0))), unit: unit.rawValue)
            tile("Sets", "\(workout.completedSets.count)")
        }
    }

    private func tile(_ label: String, _ value: String, unit: String = "") -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.title2.weight(.semibold)).monospacedDigit()
                if !unit.isEmpty { Text(unit).font(.subheadline.weight(.medium)).foregroundStyle(.secondary) }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            Text(label).font(.footnote.weight(.medium)).foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.field, in: RoundedRectangle(cornerRadius: Theme.Radius.field))
        .accessibilityElement(children: .combine)
    }

    private func exercises(_ model: WorkoutCardModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exercises")
                .font(.footnote.weight(.semibold))
                .textCase(.uppercase)
                .tracking(0.4)
                .foregroundStyle(.secondary)
            ForEach(Array(model.visibleRows(expanded: expanded).enumerated()), id: \.offset) { _, row in
                (Text(row.name).foregroundStyle(row.isWarmup ? Color.secondary : Color.primary)
                    + Text(" · \(row.sets)×").foregroundStyle(.secondary))
                    .font(.subheadline)
            }
            if model.hiddenCount > 0 { toggle(hidden: model.hiddenCount) }
        }
    }

    private func toggle(hidden: Int) -> some View {
        Button {
            withAnimation(.snappy) { expanded.toggle() }
        } label: {
            HStack(spacing: 4) {
                Text(expanded ? "Show less" : "+\(hidden) more")
                Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption.weight(.bold))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.accent)
            .frame(minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The design tucks the 44 pt target into the card's padding instead of adding a gap.
        .padding(.top, -4).padding(.bottom, -12)
        .accessibilityValue(expanded ? "Expanded" : "Collapsed")
    }
}
