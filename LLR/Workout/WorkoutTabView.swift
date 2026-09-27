import SwiftData
import SwiftUI

struct WorkoutTabView: View {
    @Environment(\.modelContext) private var context
    // Unfinished stays section-agnostic on purpose: only one workout can be in progress at a time,
    // whichever section it's from, so Resume must find it regardless.
    @Query(filter: #Predicate<Workout> { $0.endedAt == nil }) private var unfinished: [Workout]
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil && $0.sectionRaw == "gym" }, sort: \Workout.startedAt, order: .reverse)
    private var past: [Workout]
    @Query(filter: #Predicate<Routine> { $0.sectionRaw == "gym" }, sort: \Routine.createdAt, order: .reverse)
    private var routines: [Routine]
    @State private var presented: Workout?
    @State private var buildingRoutine: Routine?
    @State private var loggingPast: Workout?
    /// Set once the active-workout cover dismisses so the summary sheet doesn't fight it for presentation.
    @State private var justFinished: Workout?
    @State private var pendingSummary: Workout?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    startRow
                    Button("Log a Past Workout", systemImage: "clock.arrow.circlepath", action: logPastWorkout)
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .fullScreenCover(item: $loggingPast) { WorkoutEditorView(workout: $0, isNew: true) }

                    Text("Routines").font(.title2.weight(.semibold))
                    HStack(spacing: 16) {
                        routineTile(title: "New Routine", icon: "list.clipboard") { newRoutine() }
                        NavigationLink {
                            ExploreRoutinesView(canStart: unfinished.isEmpty, onStart: start(program:day:))
                        } label: {
                            routineTileLabel(title: "Explore Routines", icon: "magnifyingglass")
                        }
                        .buttonStyle(CardButtonStyle())
                    }

                    NavigationLink {
                        KinetoView(canStart: unfinished.isEmpty) { presented = $0 }
                    } label: {
                        KinetoEntryCard()
                    }
                    .buttonStyle(.plain)

                    if !routines.isEmpty {
                        HStack(alignment: .firstTextBaseline) {
                            Text("My Routines").font(.title3.weight(.semibold))
                            Spacer()
                            // The tab shows five; the rest live one tap away.
                            NavigationLink("See All") { RoutineListView(onStart: start(routine:)) }
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.top, 4)
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
        }
        .fullScreenCover(item: $presented, onDismiss: {
            justFinished = pendingSummary
            pendingSummary = nil
        }) { workout in
            ActiveWorkoutView(workout: workout) { pendingSummary = $0 }
        }
        .sheet(item: $justFinished) { WorkoutSummaryView(workout: $0) }
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

    /// Starts as a finished hour ending now; the editor's date pickers move it to when it happened.
    private func logPastWorkout() {
        let end = Date.now
        let workout = Workout(startedAt: end.addingTimeInterval(-3600))
        workout.endedAt = end
        context.insert(workout)
        loggingPast = workout
    }

    private func newRoutine() {
        let routine = Routine()
        context.insert(routine)
        buildingRoutine = routine
    }

    private func start(routine: Routine) {
        presented = WorkoutFactory.start(routine: routine, in: context)
    }

    private func start(program: ProgramTemplate, day: ProgramTemplate.Day) {
        let plan = RoutineLibrary.plan(for: day, in: context)
        presented = WorkoutFactory.start(plan, named: RoutineLibrary.routineName(program, day), in: context)
    }
}
