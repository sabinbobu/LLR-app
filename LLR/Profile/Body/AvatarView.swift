import SwiftUI

struct AvatarView: View {
    let image: UIImage?
    let name: String
    let size: CGFloat

    private var initials: String {
        let letters = name.split(separator: " ").prefix(2).compactMap(\.first)
        return letters.isEmpty ? "" : String(letters).uppercased()
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [Theme.accent, Theme.protein], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay {
                        if initials.isEmpty {
                            Image(systemName: "person.fill").font(.system(size: size * 0.42)).foregroundStyle(.white)
                        } else {
                            Text(initials).font(.system(size: size * 0.38, weight: .bold, design: .rounded)).foregroundStyle(.white)
                        }
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}
