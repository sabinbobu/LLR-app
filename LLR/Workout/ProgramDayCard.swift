import SwiftUI

struct ProgramDayCard: View {
    let day: ProgramTemplate.Day
    let canStart: Bool
    let onStart: () -> Void
    let onInspect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(day.name).font(.headline)
                Spacer()
                Button("Start", systemImage: "play.fill", action: onStart)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                    .disabled(!canStart)
                    .accessibilityLabel("Start \(day.name)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            Divider()
            ForEach(Array(day.exercises.enumerated()), id: \.offset) { index, entry in
                if index > 0 {
                    Divider().padding(.leading, 16)
                }
                Button { onInspect(entry.exercise) } label: { row(entry) }
                    .buttonStyle(.plain)
            }
        }
        .cardStyle()
    }

    private func row(_ entry: ProgramTemplate.Entry) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.exercise)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.setsText)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                if let rest = entry.rest {
                    Text("Rest \(RestDuration.label(rest))").font(.caption).foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
