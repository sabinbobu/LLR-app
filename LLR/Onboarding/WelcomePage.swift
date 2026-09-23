import SwiftUI

struct WelcomePage<Illustration: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let illustration: () -> Illustration

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.system(size: 40, weight: .bold))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            illustration()
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(alignment: .top) {
                    // Outline of a phone that runs off the bottom edge, fading out.
                    RoundedRectangle(cornerRadius: 56)
                        .stroke(Color(.systemGray5), lineWidth: 3)
                        .frame(height: 900)
                }
                .mask(LinearGradient(colors: [.black, .black, .black, .clear], startPoint: .top, endPoint: .bottom))
                .clipped()
                .padding(.horizontal, 12)
        }
        .padding(.horizontal, 24)
    }
}
