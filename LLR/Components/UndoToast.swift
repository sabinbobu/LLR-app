import SwiftUI

struct UndoToast: View {
    let title: String
    let undo: () -> Void

    var body: some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            Button("Undo", action: undo).font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
