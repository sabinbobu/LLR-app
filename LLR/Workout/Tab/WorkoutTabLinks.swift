import SwiftUI

/// Back care sits at the bottom: it is a gated section most people never need, but it stays one tap
/// from the tab so it is two taps from launch.
struct KinetoLinkRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.core.training")
                .foregroundStyle(Theme.accent)
                .frame(width: 32, height: 32)
                .background(Theme.accentSoft, in: Circle())
            Text("Back care (Kineto)").font(.subheadline.weight(.semibold))
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .cardStyle()
        .contentShape(Rectangle())
    }
}

/// Shown only until the first finished workout; afterwards it lives in Settings → Help.
struct GettingStartedRow: View {
    var body: some View {
        HStack {
            Text("How to get started")
            Spacer()
            Image(systemName: "arrow.right")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
    }
}
