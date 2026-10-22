import SwiftUI

/// The expanded half of the This week card: one month of days, month totals and a link to the full log.
struct MonthGrid: View {
    let workouts: [Workout]
    let starts: [Date]
    let categories: [Date: SessionCategory]
    @State private var month: Date = .now
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg

    private let calendar = Calendar.current
    private var isCurrentMonth: Bool { calendar.isDate(month, equalTo: .now, toGranularity: .month) }

    var body: some View {
        VStack(spacing: 12) {
            monthHeader
            weekdayHeader
            grid
            summary
            NavigationLink { LazyDestination { WorkoutCalendarView(workouts: workouts) } } label: {
                HStack {
                    Text("Full log").font(.subheadline.weight(.semibold))
                    Image(systemName: "chevron.right").font(.caption.weight(.bold))
                }
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { shift(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                .accessibilityLabel("Previous month")
            Spacer()
            Text(month.formatted(.dateTime.month(.wide).year())).font(.subheadline.weight(.semibold))
            Spacer()
            Button { shift(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                .disabled(isCurrentMonth)
                .accessibilityLabel("Next month")
        }
        .padding(.horizontal, -12)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(HomeModel.weekdayLetters().enumerated()), id: \.offset) { _, letter in
                Text(letter).font(.caption.weight(.semibold)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        let cells = HomeModel.monthCells(month: month, starts: starts, categories: categories)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
            ForEach(cells.indices, id: \.self) { index in
                if let day = cells[index] {
                    DayCircle(day: day)
                } else {
                    Color.clear.frame(height: 36)
                }
            }
        }
    }

    private var summary: some View {
        let totals = HomeModel.totals(workouts.sessions(in: calendar.dateInterval(of: .month, for: month)))
        let volume = unit.fromKg(totals.volumeKg).formatted(.number.precision(.fractionLength(0)))
        let count = totals.count == 1 ? "1 workout" : "\(totals.count) workouts"
        return Text("\(count) · \(Format.duration(totals.duration)) · \(volume) \(unit.rawValue)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func shift(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: month) { month = next }
    }
}
