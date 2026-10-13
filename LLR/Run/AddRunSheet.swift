import SwiftData
import SwiftUI

struct AddRunSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var draft = RunDraft()
    @State private var finished = Date.now
    @FocusState private var focused: Field?

    private enum Field { case km, hours, minutes, seconds }

    var body: some View {
        NavigationStack {
            Form {
                Section("Distance") {
                    HStack {
                        TextField("0.0", text: $draft.kmText)
                            .keyboardType(.decimalPad)
                            .focused($focused, equals: .km)
                        Text("km").foregroundStyle(.secondary)
                    }
                }
                Section("Time") {
                    HStack(spacing: 12) {
                        timeField("h", text: $draft.hoursText, field: .hours)
                        timeField("min", text: $draft.minutesText, field: .minutes)
                        timeField("sec", text: $draft.secondsText, field: .seconds)
                    }
                }
                Section {
                    DatePicker("Finished", selection: $finished, in: ...Date.now)
                }
                if let problem = draft.problem {
                    Section { Label(problem, systemImage: "exclamationmark.triangle.fill").foregroundStyle(Theme.over) }
                }
                if draft.isValid, let km = draft.distanceKm, let seconds = draft.seconds {
                    Section("Effect on your body") { RunEffectView(km: km, seconds: seconds) }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(!draft.isValid) }
            }
            .onAppear { focused = .km }
        }
    }

    private func timeField(_ unit: String, text: Binding<String>, field: Field) -> some View {
        HStack(spacing: 4) {
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused($focused, equals: field)
            Text(unit).foregroundStyle(.secondary)
        }
    }

    @MainActor
    private func save() {
        guard let km = draft.distanceKm, let seconds = draft.seconds, draft.isValid else { return }
        WorkoutFactory.addRun(distanceKm: km, seconds: seconds, finishedAt: finished, in: context)
        dismiss()
    }
}
