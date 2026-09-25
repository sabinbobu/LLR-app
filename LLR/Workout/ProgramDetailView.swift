import SwiftData
import SwiftUI

struct ProgramDetailView: View {
    let program: ProgramTemplate
    let canStart: Bool
    let onStart: (ProgramTemplate, ProgramTemplate.Day) -> Void
    @Environment(\.modelContext) private var context
    @Query private var routines: [Routine]
    @State private var inspecting: Exercise?

    private var isSaved: Bool { RoutineLibrary.isSaved(program, among: routines) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                saveButton
                VStack(alignment: .leading, spacing: 0) {
                    info("Schedule", program.schedule)
                    Divider().padding(.horizontal, 16)
                    info("Progression", program.progression)
                }
                .cardStyle()

                ForEach(program.routines) { day in
                    ProgramDayCard(day: day, canStart: canStart) {
                        onStart(program, day)
                    } onInspect: { name in
                        inspecting = RoutineLibrary.exercisesByName(in: context)[name]
                    }
                }

                source
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $inspecting) { exercise in
            NavigationStack { ExerciseDetailView(exercise: exercise, showsDoneButton: true) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(program.name).font(.title2.bold())
                Text("by \(program.author)").font(.subheadline).foregroundStyle(.secondary)
            }
            ProgramTags(program: program)
            Text(program.summary).font(.subheadline)
        }
    }

    private func info(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.5)
                .foregroundStyle(.secondary)
            Text(text).font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var source: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Source: \(program.source)")
            if let link = program.sourceURL.flatMap(URL.init(string:)) {
                Link("View original", destination: link)
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }

    // Inline rather than pinned to the bottom: a pushed screen doesn't get the floating tab
    // bar's inset, so a bottom bar would sit underneath it.
    private var saveButton: some View {
        Button {
            RoutineLibrary.save(program, into: context)
        } label: {
            if isSaved {
                Label("Added to My Routines", systemImage: "checkmark")
            } else {
                Text(program.routines.count == 1 ? "Add to My Routines" : "Add \(program.routines.count) Routines")
            }
        }
        .buttonStyle(SheetButtonStyle())
        .disabled(isSaved)
    }
}
