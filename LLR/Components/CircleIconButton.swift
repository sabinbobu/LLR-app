import SwiftUI

struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.weight(.medium))
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background(Color(.systemBackground), in: Circle())
                .overlay(Circle().stroke(Theme.border))
                .shadow(color: .black.opacity(0.06), radius: 12)
        }
        .buttonStyle(.plain)
    }
}
