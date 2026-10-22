import SwiftUI

/// "This week": one circle per day plus streak, time and volume. The chevron swaps the card into a month view.
struct WeekCard: View {
    let workouts: [Workout]
    @State private var expanded = false
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg

    var body: some View {
        let starts = workouts.map(\.startedAt)
        let categories = HomeModel.categoryByDay(workouts.map { ($0.startedAt, $0.category) })
        let week = HomeModel.week(starts: starts, categories: categories)
        VStack(alignment: .leading, spacing: 16) {
            header(count: week.workoutCount)
            if expanded {
                MonthGrid(workouts: workouts, starts: starts, categories: categories)
            } else {
                strip(week)
                stats(streak: TrainingCalendar.weekStreak(workouts: starts))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
    }

    private func header(count: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(expanded ? "This month" : "This week").font(.headline)
            if !expanded {
                Text(count == 1 ? "1 workout" : "\(count) workouts").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                withAnimation(.snappy) { expanded.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(expanded ? "Week" : "Month")
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption.weight(.bold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // The 44 pt target is tucked into the card's padding instead of stretching the header.
            .padding(.vertical, -12)
            .accessibilityValue(expanded ? "Showing month" : "Showing week")
        }
    }

    private func strip(_ week: HomeModel.Week) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(week.days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 8) {
                    Text(day.letter).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    DayCircle(day: day)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func stats(streak: Int) -> some View {
        let interval = Calendar.current.dateInterval(of: .weekOfYear, for: .now)
        let totals = HomeModel.totals(workouts.sessions(in: interval))
        return HStack(spacing: 8) {
            StatTile(label: "Streak", value: "\(streak)", unit: "wk", icon: "flame.fill", iconTint: streak > 0 ? .orange : .secondary)
            StatTile(label: "Time", value: Format.duration(totals.duration))
            StatTile(label: "Volume", value: unit.fromKg(totals.volumeKg).formatted(.number.precision(.fractionLength(0))), unit: unit.rawValue)
        }
    }
}

/// One day of the week strip or month grid. Trained days fill with their session colour, so
/// a Push/Pull/Legs week reads at a glance; uncategorised and run days use the accent.
struct DayCircle: View {
    let day: HomeModel.WeekDay

    var body: some View {
        Text("\(day.number)")
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(numberColor)
            .frame(width: 36, height: 36)
            .background(day.trained ? fill : .clear, in: Circle())
            .overlay(Circle().strokeBorder(Theme.accent, lineWidth: day.isToday ? 2 : 0))
            // The weekday letters repeat (T, T, S, S), so VoiceOver gets the date and state instead.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(day.number)\(day.isToday ? ", today" : "")\(day.trained ? ", trained" : "")")
    }

    private var fill: Color { day.category == .none ? Theme.primaryFill : day.category.color }

    private var numberColor: Color {
        if day.trained { return .white }
        if day.isToday { return Theme.accent }
        return day.isFuture ? .secondary : .primary
    }
}

struct StatTile: View {
    let label: String
    let value: String
    var unit: String = ""
    var icon: String?
    var iconTint: Color = .secondary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if let icon { Image(systemName: icon).font(.subheadline).foregroundStyle(iconTint).padding(.trailing, 2) }
                Text(value).font(.title3.weight(.semibold)).monospacedDigit()
                if !unit.isEmpty { Text(unit).font(.footnote.weight(.medium)).foregroundStyle(.secondary) }
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
}

extension Array where Element == Workout {
    /// Only the workouts inside `interval` are turned into sessions: volume is walked off SwiftData,
    /// so doing it for the whole history on every render would be wasted work.
    func sessions(in interval: DateInterval?) -> [HomeModel.Session] {
        guard let interval else { return [] }
        return filter { interval.contains($0.startedAt) }
            .map { HomeModel.Session(start: $0.startedAt, duration: $0.duration, volumeKg: $0.volumeKg) }
    }
}
