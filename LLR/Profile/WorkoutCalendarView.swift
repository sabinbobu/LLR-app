import SwiftUI

struct WorkoutCalendarView: View {
    let workouts: [Workout]
    @State private var month: Date = .now

    private let calendar = Calendar.current
    private var trainedDays: Set<Date> {
        TrainingCalendar.trainedDays(in: month, workouts: workouts.map(\.startedAt), calendar: calendar)
    }
    private var categories: [Date: SessionCategory] {
        TrainingCalendar.categoryByDay(in: month, workouts: workouts.map { ($0.startedAt, $0.category) }, calendar: calendar)
    }
    private var streak: Int {
        TrainingCalendar.weekStreak(workouts: workouts.map(\.startedAt), calendar: calendar)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Label("\(streak) week\(streak == 1 ? "" : "s")", systemImage: "flame.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(streak > 0 ? .orange : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ActivityHeatmapView(workouts: workouts)

                monthHeader
                weekdayHeader
                grid
            }
            .padding()
        }
        .navigationTitle("Workout Log")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(month.formatted(.dateTime.month(.wide).year())).font(.headline)
            Spacer()
            Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                .disabled(calendar.isDate(month, equalTo: .now, toGranularity: .month))
        }
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(orderedWeekdaySymbols(), id: \.self) { symbol in
                Text(symbol).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        let days = daysInMonth()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days.indices, id: \.self) { index in
                if let day = days[index] {
                    let start = calendar.startOfDay(for: day)
                    let trained = trainedDays.contains(start)
                    let tint = categories[start]?.color ?? Theme.accent
                    Text("\(calendar.component(.day, from: day))")
                        .font(.subheadline)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(trained ? tint : Color.clear, in: Circle())
                        .foregroundStyle(trained ? Color.white : Color.primary)
                } else {
                    Color.clear.frame(minHeight: 36)
                }
            }
        }
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: month) { month = next }
    }

    private func orderedWeekdaySymbols() -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    /// Leading `nil`s pad the grid so day 1 lands under its actual weekday.
    private func daysInMonth() -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        var day = interval.start
        while day < interval.end {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }
}
