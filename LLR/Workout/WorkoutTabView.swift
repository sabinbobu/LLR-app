import SwiftData
import SwiftUI

struct WorkoutTabView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { $0.endedAt == nil }) private var unfinished: [Workout]
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil }, sort: \Workout.startedAt, order: .reverse)
    private var past: [Workout]
    @State private var presented: Workout?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let current = unfinished.first {
                        actionRow(icon: "play.fill", title: "Resume Workout", detail: current.title) {
                            presented = current
                        }
                    } else {
                        actionRow(icon: "plus", title: "Start Empty Workout") {
                            presented = WorkoutFactory.start(copying: nil, in: context)
                        }
                    }

                    if !past.isEmpty {
                        Text("Repeat a Workout")
                            .font(.title2.weight(.semibold))
                            .padding(.top, 8)
                        ForEach(past.prefix(10)) { workout in
                            repeatRow(workout)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Workout")
        }
        .fullScreenCover(item: $presented) { ActiveWorkoutView(workout: $0) }
    }

    private func actionRow(icon: String, title: String, detail: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon).font(.title2)
                VStack(alignment: .leading) {
                    Text(title).font(.title3)
                    if let detail {
                        Text(detail).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 22)
            .frame(minHeight: 72)
        }
        .buttonStyle(CardButtonStyle())
    }

    private func repeatRow(_ workout: Workout) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title).font(.headline)
                Text(workout.orderedExercises.compactMap { $0.exercise?.name }.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Button("Repeat") {
                presented = WorkoutFactory.start(copying: workout, in: context)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!unfinished.isEmpty)
        }
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1.5))
    }
}
