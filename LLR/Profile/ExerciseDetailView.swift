import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    /// Pushed from the exercise list it gets a back button; presented as a sheet it needs its own way out.
    var showsDoneButton = false
    @Environment(\.dismiss) private var dismiss
    @State private var page: Page = .summary
    @State private var editing = false

    private enum Page: String, CaseIterable, Identifiable {
        case summary = "Summary"
        case howTo = "How to"

        var id: Self { self }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if exercise.isCustom && !exercise.media.isEmpty {
                    ExerciseMediaSection(items: .constant(exercise.media.sorted { $0.createdAt < $1.createdAt }.map(\.item)))
                }
                Picker("Section", selection: $page) {
                    ForEach(Page.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                switch page {
                case .summary:
                    ExerciseOverviewCard(exercise: exercise)
                    ExerciseProgressView(exercise: exercise)
                case .howTo:
                    ExerciseStepsView(steps: exercise.instructions)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .navigationTitle("Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            if exercise.isCustom {
                ToolbarItem(placement: .primaryAction) { Button("Edit") { editing = true } }
            }
        }
        .sheet(isPresented: $editing) { ExerciseEditorView(editing: exercise) }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ExerciseIconTile(size: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name).font(.title2.bold())
                Text(exercise.detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
