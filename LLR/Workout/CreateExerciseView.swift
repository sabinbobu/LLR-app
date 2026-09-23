import SwiftUI

struct CreateExerciseView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var group: MuscleGroup = .chest
    let onCreate: (Exercise) -> Void

    init(initialName: String = "", onCreate: @escaping (Exercise) -> Void) {
        _name = State(initialValue: initialName)
        self.onCreate = onCreate
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Exercise name", text: $name)
                Picker("Muscle group", selection: $group) {
                    ForEach(MuscleGroup.allCases) { Text($0.rawValue).tag($0) }
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let exercise = Exercise(name: trimmed, muscleGroup: group.rawValue, isCustom: true)
                        context.insert(exercise)
                        dismiss()
                        onCreate(exercise)
                    }
                    .disabled(trimmed.isEmpty)
                }
            }
        }
    }
}
