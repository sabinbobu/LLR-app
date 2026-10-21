import SwiftUI

/// Home's one primary action: start the suggested session, or resume the one in progress.
struct StartWorkoutCard: View {
    let title: String
    let subtitle: String
    var systemImage: String = "play.fill"
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.title3.weight(.semibold))
                    Text(subtitle).font(.subheadline).lineLimit(2).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(Theme.primaryFill)
                    .frame(width: 48, height: 48)
                    .background(Color.white, in: Circle())
            }
            .foregroundStyle(Color.white)
            .padding(.vertical, Theme.cardPadding)
            .padding(.leading, 20)
            .padding(.trailing, Theme.cardPadding)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            .background(Theme.primaryFill, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
            .shadow(color: Theme.primaryFill.opacity(scheme == .light ? 0.28 : 0), radius: 8, y: 4)
        }
        .buttonStyle(HeroCardButtonStyle())
        .accessibilityElement(children: .combine)
    }
}
