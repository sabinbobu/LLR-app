import SwiftUI

struct WeekCard: View {
    let days: [HomeModel.Day]
    let workoutCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("This week").font(.headline)
                Spacer()
                Text(workoutCount == 1 ? "1 workout" : "\(workoutCount) workouts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 0) {
                ForEach(days) { DayCell(day: $0).frame(maxWidth: .infinity) }
            }
        }
        .surfaceCard()
    }
}

private struct DayCell: View {
    let day: HomeModel.Day

    var body: some View {
        VStack(spacing: 8) {
            Text(day.letter).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text("\(day.number)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(numberColor)
                .frame(width: 36, height: 36)
                .background(day.state == .trained ? Theme.primaryFill : Color.clear, in: Circle())
                .overlay(Circle().strokeBorder(Theme.accent, lineWidth: day.state == .today ? 2 : 0))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(day.date.formatted(.dateTime.weekday(.wide).day()) + (day.state == .trained ? ", trained" : ""))
    }

    // Future days are dimmed because they have not happened yet, not because they are off.
    private var numberColor: Color {
        switch day.state {
        case .trained: Color.white
        case .today: Theme.accent
        case .future: Color.secondary
        case .rest: Color.primary
        }
    }
}
