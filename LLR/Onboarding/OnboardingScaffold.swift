import SwiftUI

struct OnboardingScaffold<Content: View>: View {
    let title: String
    var showsBack = true
    var showsPrivacyNote = false
    var canContinue = true
    let onContinue: () -> Void
    @ViewBuilder let content: () -> Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if showsBack {
                CircleIconButton(systemName: "arrow.left") { dismiss() }
            }
            Text(title)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
            content()
            Spacer(minLength: 0)
            if showsPrivacyNote {
                Text("Your data is private and secure.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            Button("Continue", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canContinue)
        }
        .padding(.horizontal, 24)
        .padding(.top, showsBack ? 8 : 40)
        .padding(.bottom, 16)
    }
}
