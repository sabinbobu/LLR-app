import SwiftData
import SwiftUI

struct WorkoutTabView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { $0.endedAt == nil }) private var unfinished: [Workout]
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil }, sort: \Workout.startedAt, order: .reverse)
    private var past: [Workout]
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]
    @State private var presented: Workout?
    @State private var buildingRoutine: Routine?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    startRow

                    Text("Routines").font(.title2.weight(.semibold))
                    HStack(spacing: 16) {
                        routineTile(title: "New Routine", icon: "list.clipboard") { newRoutine() }
                        NavigationLink {
                            RoutineListView(onStart: start(routine:))
                        } label: {
                            routineTileLabel(title: "Explore Routines", icon: "magnifyingglass")
                        }
                        .buttonStyle(CardButtonStyle())
                    }

                    if !routines.isEmpty {
                        Text("My Routines").font(.title3.weight(.semibold)).padding(.top, 4)
                        ForEach(routines.prefix(5)) { routine in
                            routineRow(routine)
                        }
                    }

                    if !past.isEmpty {
                        Text("Repeat a Workout").font(.title3.weight(.semibold)).padding(.top, 4)
                        ForEach(past.prefix(10)) { workout in
                            repeatRow(workout)
                        }
                    }

                    NavigationLink {
                        RoutineHelpView()
                    } label: {
                        HStack {
                            Text("How to get started")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Workout")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("PRO")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(.yellow.opacity(0.3), in: Capsule())
                }
            }
        }
        .fullScreenCover(item: $presented) { ActiveWorkoutView(workout: $0) }
        .sheet(item: $buildingRoutine) { RoutineBuilderView(routine: $0) }
    }

    private var startRow: some View {
        Group {
            if let current = unfinished.first {
                actionRow(icon: "play.fill", title: "Resume Workout", detail: current.title) {
                    presented = current
                }
            } else {
                actionRow(icon: "plus", title: "Start Empty Workout") {
                    presented = WorkoutFactory.start(copying: nil, in: context)
                }
            }
        }
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

    private func routineTile(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { routineTileLabel(title: title, icon: icon) }
            .buttonStyle(CardButtonStyle())
    }

    private func routineTileLabel(title: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.title2)
            Text(title)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
    }

    private func routineRow(_ routine: Routine) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name.isEmpty ? "Untitled Routine" : routine.name).font(.headline)
                Text(routine.orderedExercises.compactMap { $0.exercise?.name }.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Button("Start") { start(routine: routine) }
                .buttonStyle(.borderedProminent)
                .disabled(routine.orderedExercises.isEmpty || !unfinished.isEmpty)
        }
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1.5))
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

    private func newRoutine() {
        let routine = Routine()
        context.insert(routine)
        buildingRoutine = routine
    }

    private func start(routine: Routine) {
        presented = WorkoutFactory.start(routine: routine, in: context)
    }
}
