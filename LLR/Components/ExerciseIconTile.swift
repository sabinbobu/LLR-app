import SwiftUI

struct ExerciseIconTile: View {
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: "dumbbell")
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(Theme.accent)
            .frame(width: size, height: size)
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: size * 0.26))
            .accessibilityHidden(true)
    }
}
