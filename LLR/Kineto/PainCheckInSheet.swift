import SwiftUI

/// Runs before a Kineto session exists: three red-flag screening questions (condensed from the
/// NHS emergency list — any "yes" stops here and creates nothing), then back/leg pain. Only after
/// this clears does `WorkoutFactory` create the workout.
struct PainCheckInSheet: View {
    let routine: Routine
    var onStart: (Workout) -> Void
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var answers: [Bool] = [false, false, false]
    @State private var showingStop = false
    @State private var backPain: Double = 0
    @State private var legPain: Double = 0

    private let questions = [
        "Any new numbness, tingling or weakness in your legs, or around your groin?",
        "Any new bladder or bowel changes, or changes in sexual function?",
        "Any severe pain that started suddenly, chest pain, or pain following a fall or accident?",
    ]

    private var anyYes: Bool { answers.contains(true) }

    var body: some View {
        NavigationStack {
            if showingStop {
                RedFlagsView(mode: .stop) { dismiss() }
            } else {
                form
            }
        }
        .interactiveDismissDisabled()
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Before you start").sectionLabel()
                    ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                        questionRow(question, isYes: answers[index]) { answers[index] = $0 }
                    }
                }
                VStack(alignment: .leading, spacing: 16) {
                    Text("How's your pain right now?").sectionLabel()
                    PainSlider(title: "Back pain", value: $backPain)
                    PainSlider(title: "Leg pain", value: $legPain)
                }
            }
            .padding(16)
            .padding(.bottom, 80)
        }
        .background(Theme.background)
        .navigationTitle(routine.name.isEmpty ? "Check-in" : routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        }
        .safeAreaInset(edge: .bottom) {
            Button("Start Session") {
                if anyYes {
                    showingStop = true
                } else {
                    let workout = WorkoutFactory.start(
                        routine: routine, backPainBefore: Int(backPain), legPainBefore: Int(legPain), in: context
                    )
                    // This sheet must close itself — starting the workout only sets an ancestor's
                    // state (WorkoutTabView's `presented`), which doesn't dismiss a sheet on its own.
                    dismiss()
                    onStart(workout)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
    }

    private func questionRow(_ text: String, isYes: Bool, onChange: @escaping (Bool) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text).font(.subheadline)
            PillToggle(options: [false, true], selection: Binding(get: { isYes }, set: onChange)) { $0 ? "Yes" : "No" }
        }
        .padding(16)
        .cardStyle()
    }
}

/// Shared by check-in and check-out: a 0–10 pain score with the number shown live.
struct PainSlider: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text("\(Int(value))/10").font(.subheadline.weight(.semibold)).monospacedDigit()
            }
            Slider(value: $value, in: 0...10, step: 1)
        }
    }
}
