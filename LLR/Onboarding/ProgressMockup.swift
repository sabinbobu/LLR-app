import Charts
import SwiftUI

struct ProgressMockup: View {
    private let points: [(week: Int, kg: Double)] = [
        (0, 32), (1, 36), (2, 34), (3, 41), (4, 38), (5, 44), (6, 43), (7, 50), (8, 57),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: "dumbbell.fill")
                    .font(.title3)
                    .frame(width: 52, height: 52)
                    .overlay(Circle().stroke(Theme.border))
                Text("Bench Press (Barbell)")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
            }
            (Text("57 kg ").bold() + Text("this week"))
                .font(.title3)
            Chart(points, id: \.week) { point in
                LineMark(x: .value("Week", point.week), y: .value("kg", point.kg))
                PointMark(x: .value("Week", point.week), y: .value("kg", point.kg))
            }
            .foregroundStyle(Theme.accent)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: [30, 45, 60]) { value in
                    AxisGridLine()
                    AxisValueLabel { Text("\(value.as(Int.self) ?? 0) kg") }
                }
            }
            .frame(height: 180)
            HStack {
                Text("Heaviest Weight")
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .background(Theme.accent, in: Capsule())
                Text("One Rep Max")
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Theme.card, in: Capsule())
            }
        }
    }
}
