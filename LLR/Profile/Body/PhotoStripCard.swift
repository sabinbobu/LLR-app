import SwiftUI

struct PhotoStripCard: View {
    let photos: [ProgressPhoto]
    let trend: [WeightTrend.Point]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Progress photos").font(.headline)
                Spacer()
                NavigationLink("See all") { ProgressPhotosView() }.font(.subheadline.weight(.medium))
            }
            if photos.isEmpty {
                NavigationLink { ProgressPhotosView() } label: {
                    Label("Add your first photo: same spot, same light, every few weeks", systemImage: "camera")
                        .font(.footnote)
                        .frame(maxWidth: .infinity, minHeight: 88)
                        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photos.prefix(12)) { photo in
                            thumbnail(photo)
                        }
                    }
                }
                if photos.count >= 2 {
                    NavigationLink {
                        PhotoCompareView(photos: photos, trend: trend)
                    } label: {
                        Label("Compare before & after", systemImage: "square.split.2x1")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private func thumbnail(_ photo: ProgressPhoto) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let image = UIImage(data: photo.imageData) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Color(.systemGray5)
            }
            Text(photo.takenAt.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(6)
        }
        .frame(width: 88, height: 116)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
