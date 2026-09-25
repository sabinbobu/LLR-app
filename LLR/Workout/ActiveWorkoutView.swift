import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @State private var model: ActiveWorkoutModel
    @State private var showingPicker = false
    @State private var confirmDiscard = false
    @State private var showingKinetoCheckOut = false

    init(workout: Workout) {
        _model = State(initialValue: ActiveWorkoutModel(workout: workout))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    stats
                    ForEach(model.workout.orderedExercises) { entry in
                        ExerciseLogCard(entry: entry, model: model, unit: unit)
                    }
                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Button("Discard Workout", role: .destructive) { confirmDiscard = true }
                        .padding(.bottom, 24)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                if model.restTimer.isRunning {
                    RestTimerBar(timer: model.restTimer)
                }
            }
            .animation(.snappy, value: model.restTimer.isRunning)
            .onAppear { LiveWorkoutActivity.sync(startIfNeeded: true) }
            // Typed weight/reps change the Lock Screen target; leaving the app is when that matters.
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { LiveWorkoutActivity.sync() }
            }
            .sensoryFeedback(.success, trigger: model.restTimer.finishedCount)
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .sheet(isPresented: $showingPicker) {
                if model.workout.section == .kineto {
                    KinetoCatalogView(mode: .pick { exercise, level in model.add(exercise, level: level) })
                } else {
                    ExercisePickerView { $0.forEach(model.add) }
                }
            }
            .sheet(isPresented: $showingKinetoCheckOut) {
                PainCheckOutSheet(model: model) { dismiss() }
            }
            .confirmationDialog("Discard this workout?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard Workout", role: .destructive) {
                    model.discard()
                    dismiss()
                }
            }
        }
    }

    private var stats: some View {
        HStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Duration").font(.caption).foregroundStyle(.secondary)
                Text(model.workout.startedAt, style: .timer)
                    .foregroundStyle(Theme.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Volume").font(.caption).foregroundStyle(.secondary)
                Text("\(unit.format(kg: model.workout.volumeKg)) \(unit.rawValue)")
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Sets").font(.caption).foregroundStyle(.secondary)
                Text("\(model.workout.completedSets.count)")
            }
            Spacer()
        }
        .monospacedDigit()
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            // Minimise, not cancel: the workout stays open and resumable from the Workout tab.
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Finish") {
                if model.workout.section == .kineto {
                    showingKinetoCheckOut = true
                } else {
                    model.finish()
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}
