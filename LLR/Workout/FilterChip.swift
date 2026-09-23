import SwiftUI

struct FilterChip: View {
    let title: String
    let options: [String]
    @Binding var selection: String?

    var body: some View {
        Menu {
            Button("All") { selection = nil }
            ForEach(options, id: \.self) { option in
                Button(option) { selection = option }
            }
        } label: {
            Text(selection ?? title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(selection == nil ? Color.secondary : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Theme.card, in: Capsule())
        }
    }
}
