import SwiftUI

/// Jump to any past day in one tap instead of stepping back a day at a time.
struct FuelDayPickerSheet: View {
    @Binding var day: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker("Day", selection: pick, in: ...Date.now, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Go to day")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Today") {
                            day = Calendar.current.startOfDay(for: .now)
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }

    /// Choosing a day applies and closes at once; the sheet has no separate confirm step to forget.
    private var pick: Binding<Date> {
        Binding(
            get: { day },
            set: {
                day = Calendar.current.startOfDay(for: $0)
                dismiss()
            }
        )
    }
}
