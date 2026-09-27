import PhotosUI
import SwiftData
import SwiftUI

struct ProgressPhotosView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ProgressPhoto.takenAt, order: .reverse) private var photos: [ProgressPhoto]
    @State private var pickerItem: PhotosPickerItem?
    @State private var viewing: ProgressPhoto?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 4)]

    var body: some View {
        ScrollView {
            if photos.isEmpty {
                EmptyStateCard(systemImage: "camera", message: "No progress photos yet")
                    .padding()
            } else {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(photos) { photo in
                        thumbnail(photo)
                    }
                }
                .padding(4)
            }
        }
        .navigationTitle("Progress Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Image(systemName: "plus")
            }
        }
        .onChange(of: pickerItem) { _, item in
            Task { await add(item) }
        }
        .sheet(item: $viewing) { photo in
            viewer(photo)
        }
    }

    private func thumbnail(_ photo: ProgressPhoto) -> some View {
        Group {
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
            } else {
                Color(.systemGray5)
            }
        }
        .frame(minHeight: 100)
        .onTapGesture { viewing = photo }
    }

    private func viewer(_ photo: ProgressPhoto) -> some View {
        NavigationStack {
            Group {
                if let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage).resizable().scaledToFit()
                }
            }
            .navigationTitle(photo.takenAt.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(role: .destructive) {
                    context.delete(photo)
                    viewing = nil
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    private func add(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        let resized = Self.downscaled(data, maxDimension: 2048) ?? data
        context.insert(ProgressPhoto(imageData: resized))
        pickerItem = nil
    }

    /// Keeps the store lean: a phone photo can be several MB, and a progress photo doesn't need full resolution.
    private static func downscaled(_ data: Data, maxDimension: CGFloat) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        guard scale < 1 else { return image.jpegData(compressionQuality: 0.85) }
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.85)
    }
}
