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
    @Environment(ActiveWorkoutPresenter.self) private var presenter
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil && $0.sectionRaw == "run" }) private var runs: [Workout]
    @State private var addingRun = false
    @State private var buildingRoutine: Routine?
    @State private var loggingPast: Workout?
    @State private var openRoutineID: UUID?
    @State private var deleter = RoutineDeleter()

    private var recent: [Routine] { WorkoutTabModel.recentRoutines(routines) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    startRow
                    HStack(spacing: 12) {
                        Button { addingRun = true } label: { Label("Add Run", systemImage: "figure.run") }
                            .buttonStyle(.secondaryRole)
                        Button(action: logPastWorkout) { Label("Log Past", systemImage: "clock.arrow.circlepath") }
                            .buttonStyle(.secondaryRole)
                            .fullScreenCover(item: $loggingPast) { WorkoutEditorView(workout: $0, isNew: true) }
                    }

                    if !recent.isEmpty {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Quick start").font(.title3.weight(.semibold))
                            Spacer()
                            NavigationLink("See All") { RoutineListView(onStart: start(routine:)) }
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.top, 4)
                        ForEach(recent) { routine in
                            routineRow(routine)
                        }
                    }
                    RoutineTiles(onNew: newRoutine, canStart: unfinished.isEmpty, onStart: start(program:day:))

                    let repeats = WorkoutTabModel.repeatCandidates(past)
                    if !repeats.isEmpty {
                        RepeatLastRow(workouts: repeats, canStart: unfinished.isEmpty) { workout in
                            presenter.present(WorkoutFactory.start(copying: workout, in: context))
                        }
                    }
                    if !runs.isEmpty { RunSummaryCard(runs: runs) }

                    NavigationLink {
                        KinetoView(canStart: unfinished.isEmpty) { presenter.present($0) }
                    } label: {
                        KinetoLinkRow()
                    }
                    .buttonStyle(.plain)

                    if WorkoutTabModel.showsGettingStarted(finishedGymWorkouts: past.count) {
                        NavigationLink { RoutineHelpView() } label: { GettingStartedRow() }
                            .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .closesSwipeOnScroll($openRoutineID)
            .routineUndoToast(deleter)
            .navigationTitle("Workout")
        }
        .sheet(item: $buildingRoutine) { RoutineBuilderView(routine: $0) }
        .sheet(isPresented: $addingRun) { AddRunSheet() }
    }

    /// One large primary button: the most common thing to do on this tab is start a session.
    private var startRow: some View {
        Group {
            if let current = unfinished.first {
                Button { presenter.present(current) } label: {
                    Label("Resume: \(current.title)", systemImage: "play.fill")
                        .font(.title3.weight(.semibold))
                        .padding(.vertical, 10)
                }
            } else {
                Button { presenter.present(WorkoutFactory.start(copying: nil, in: context)) } label: {
                    Label("Start Workout", systemImage: "plus")
                        .font(.title3.weight(.semibold))
                        .padding(.vertical, 10)
                }
            }
        }
        .buttonStyle(.primaryRole)
    }

    private func routineRow(_ routine: Routine) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(routine.name.isEmpty ? "Untitled Routine" : routine.name).font(.headline)
                    CategoryChip(category: routine.category)
                }
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
        // Edit stays enabled mid-workout: it changes the template, never the running workout.
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture { buildingRoutine = routine }
        .swipeToDelete(
            id: routine.id,
            openID: $openRoutineID,
            onEdit: { buildingRoutine = routine },
            onDelete: { deleter.delete(routine, in: context) }
        )
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
        presenter.present(WorkoutFactory.start(routine: routine, in: context))
    }

    private func start(program: ProgramTemplate, day: ProgramTemplate.Day) {
        let plan = RoutineLibrary.plan(for: day, in: context)
        presenter.present(WorkoutFactory.start(plan, named: RoutineLibrary.routineName(program, day),
                                               category: .infer(fromDayName: day.name), in: context))
    }
}
