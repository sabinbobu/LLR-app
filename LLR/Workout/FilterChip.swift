import SwiftUI

struct FilterChip: View {
    let title: String
    let options: [String]
    @Binding var selection: String?

    private var isActive: Bool { selection != nil }

    var body: some View {
        Menu {
            Picker(title, selection: $selection) {
                Text("All").tag(String?.none)
                ForEach(options, id: \.self) { Text($0).tag(Optional($0)) }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selection ?? title).lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isActive ? Theme.accent : Color.secondary)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isActive ? Theme.accent : Color.primary)
            .padding(.leading, 14)
            .padding(.trailing, 10)
            .frame(height: 36)
            .background(isActive ? Theme.accentSoft : Theme.surface, in: Capsule())
            .overlay(Capsule().stroke(isActive ? Theme.accent.opacity(0.4) : Color(.systemGray4)))
        }
        .accessibilityLabel("\(title) filter")
        .accessibilityValue(selection ?? "All")
    }
}
