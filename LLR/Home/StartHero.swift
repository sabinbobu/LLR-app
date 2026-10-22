import SwiftUI

/// The one big Start button. The caller decides what it starts (next routine, blank, or resume).
struct StartHero: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.title3.weight(.semibold))
                    Text(subtitle).font(.subheadline).lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "play.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.primaryFill)
                    .frame(width: 48, height: 48)
                    .background(.white, in: Circle())
            }
            .foregroundStyle(.white)
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 16))
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            .background(Theme.primaryFill, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
            .shadow(color: Theme.accent.opacity(scheme == .light ? 0.28 : 0), radius: 8, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressDimStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}

private struct PressDimStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.85 : 1)
    }
}
