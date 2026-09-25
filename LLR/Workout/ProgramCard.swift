import SwiftUI

struct ProgramCard: View {
    let program: ProgramTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(program.name).font(.headline)
                    Text("by \(program.author)").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            Text(program.summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            ProgramTags(program: program)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .contentShape(Rectangle())
    }
}

struct ProgramTags: View {
    let program: ProgramTemplate

    var body: some View {
        HStack(spacing: 6) {
            tag(program.level.title)
            tag("\(program.daysPerWeek) days/week")
            tag(program.equipment.title)
        }
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .frame(height: 24)
            // A translucent fill reads on both the white cards and the grey detail page.
            .background(Color(.tertiarySystemFill), in: Capsule())
    }
}
