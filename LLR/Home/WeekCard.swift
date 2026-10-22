import SwiftUI

/// "This week": one circle per day, filled when something was logged.
struct WeekCard: View {
    let week: HomeModel.Week

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("This week").font(.headline)
                Spacer()
                Text(week.workoutCount == 1 ? "1 workout" : "\(week.workoutCount) workouts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 0) {
                ForEach(Array(week.days.enumerated()), id: \.offset) { _, day in
                    column(day)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
    }

    private func column(_ day: HomeModel.WeekDay) -> some View {
        VStack(spacing: 8) {
            Text(day.letter).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text("\(day.number)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(numberColor(day))
                .frame(width: 36, height: 36)
                .background(day.trained ? Theme.primaryFill : .clear, in: Circle())
                .overlay(Circle().strokeBorder(Theme.accent, lineWidth: day.isToday ? 2 : 0))
        }
        .frame(maxWidth: .infinity)
        // The weekday letters repeat (T, T, S, S), so VoiceOver gets the date and state instead.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(day.number)\(day.isToday ? ", today" : "")\(day.trained ? ", trained" : "")")
    }

    private func numberColor(_ day: HomeModel.WeekDay) -> Color {
        if day.trained { return .white }
        if day.isToday { return Theme.accent }
        return day.isFuture ? .secondary : .primary
    }
}
