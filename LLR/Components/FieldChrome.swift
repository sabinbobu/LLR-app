import SwiftUI

/// A quiet filled input that lifts to the surface colour with an accent ring while focused,
/// so the cell being typed into is obvious mid-entry.
struct FieldChrome: ViewModifier {
    let isFocused: Bool
    var cornerRadius: CGFloat = 10
    var fill: Color = Theme.field

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        content
            .background(isFocused ? Theme.surface : fill, in: shape)
            .overlay(shape.stroke(isFocused ? Theme.accent : Theme.border, lineWidth: 1))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius + 3)
                    .stroke(Theme.accent.opacity(isFocused ? 0.15 : 0), lineWidth: 3)
                    .padding(-1.5)
            )
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

extension View {
    func fieldChrome(isFocused: Bool, cornerRadius: CGFloat = 10, fill: Color = Theme.field) -> some View {
        modifier(FieldChrome(isFocused: isFocused, cornerRadius: cornerRadius, fill: fill))
    }
}
