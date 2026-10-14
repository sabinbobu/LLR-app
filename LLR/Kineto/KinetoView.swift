import SwiftData
import SwiftUI

/// The Kineto hub: gate on first use (and after a catalog update), persistent disclaimer, saved
/// back-care routines, catalog browser and pain history. `onStart` bubbles up to the same
/// `presented: Workout?` state `WorkoutTabView` already uses for gym sessions — only one workout
/// can be active at a time, whichever section it's from.
struct KinetoView: View {
    let canStart: Bool
    let onStart: (Workout) -> Void
    @Environment(\.modelContext) private var context
    @AppStorage(StorageKey.kinetoClearedVersion) private var clearedVersion = 0
    @State private var showingGate = false
    @State private var buildingRoutine: Routine?
    @State private var checkingIn: Routine?
    /// Held until the check-in sheet has finished closing: the workout cover lives on the tab root,
    /// and a presentation requested while a sheet is still dismissing is silently dropped.
    @State private var startedWorkout: Workout?
    @Query(filter: #Predicate<Routine> { $0.sectionRaw == "kineto" }, sort: \Routine.createdAt, order: .reverse)
    private var routines: [Routine]

    private var isCleared: Bool { KinetoCatalog.isCleared(clearedVersion) }
    /// A second presentation requested while one is up or animating is lost, which reads as a dead button.
    private var modalActive: Bool { showingGate || buildingRoutine != nil || checkingIn != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                KinetoBanner()

                HStack(spacing: 16) {
                    tile(title: "New Routine", icon: "list.clipboard") { if !modalActive { newRoutine() } }
                    NavigationLink {
                        KinetoCatalogView(mode: .browse)
                    } label: {
                        tileLabel(title: "Browse Catalog", icon: "magnifyingglass")
                    }
                    .buttonStyle(CardButtonStyle())
                }

                if !routines.isEmpty {
                    Text("My Kineto Routines").font(.title3.weight(.semibold))
                    ForEach(routines) { routine in
                        routineRow(routine)
                    }
                }

                NavigationLink {
                    PainHistoryView()
                } label: {
                    HStack {
                        Label("Pain history", systemImage: "chart.xyaxis.line")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .cardStyle()
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(Theme.background)
        .navigationTitle("Kineto")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if !isCleared, !modalActive { showingGate = true } }
        .fullScreenCover(isPresented: $showingGate) {
            KinetoGateView { showingGate = false }
        }
        .sheet(item: $buildingRoutine) { RoutineBuilderView(routine: $0) }
        .sheet(item: $checkingIn, onDismiss: {
            if let workout = startedWorkout {
                startedWorkout = nil
                onStart(workout)
            }
        }) { routine in
            PainCheckInSheet(routine: routine) { startedWorkout = $0 }
        }
    }

    private func tile(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { tileLabel(title: title, icon: icon) }
            .buttonStyle(CardButtonStyle())
    }

    private func tileLabel(title: String, icon: String) -> some View {
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
            Button("Start") { if !modalActive { checkingIn = routine } }
                .buttonStyle(.borderedProminent)
                .disabled(routine.orderedExercises.isEmpty || !canStart)
        }
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1.5))
    }

    private func newRoutine() {
        let routine = Routine()
        routine.section = .kineto
        context.insert(routine)
        buildingRoutine = routine
    }
}
