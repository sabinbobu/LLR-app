import PhotosUI
import SwiftUI

/// Personal photos and videos for an exercise. Editable, it adds from the library or camera and
/// removes items from `items` only; the editor deletes files on save, so Cancel loses nothing.
struct ExerciseMediaSection: View {
    @Binding var items: [ExerciseMediaItem]
    var editable = false
    var session: ExerciseMediaSession?
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var importing = 0
    @State private var showingCamera = false
    @State private var cameraImage: UIImage?
    @State private var cameraVideo: URL?
    @State private var viewing: ExerciseMediaItem?
    @State private var failure: String?

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !items.isEmpty || importing > 0 {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(items) { item in
                        Button { viewing = item } label: { ExerciseMediaThumbnail(item: item) }
                            .buttonStyle(.plain)
                    }
                    ForEach(0..<importing, id: \.self) { _ in
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 96)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            if editable { addButtons }
            if let failure {
                Text(failure).font(.footnote).foregroundStyle(.red)
            }
        }
        .onChange(of: pickerItems) { _, picked in
            guard !picked.isEmpty else { return }
            pickerItems = []
            for item in picked { run { try await importPicked(item) } }
        }
        .onChange(of: cameraImage) { _, image in
            guard let image else { return }
            cameraImage = nil
            run { try await Task.detached(priority: .userInitiated) { try ExerciseMediaStore.savePhoto(image) }.value }
        }
        .onChange(of: cameraVideo) { _, url in
            guard let url else { return }
            cameraVideo = nil
            // Video encoding should not block the main actor
            run {
                try await Task.detached(priority: .userInitiated) {
                    try await ExerciseMediaStore.saveVideo(from: url)
                }.value
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(image: $cameraImage, videoURL: $cameraVideo).ignoresSafeArea()
        }
        .sheet(item: $viewing) { item in
            ExerciseMediaViewer(item: item, onDelete: editable ? { items.removeAll { $0 == item } } : nil)
        }
    }

    private var addButtons: some View {
        HStack(spacing: 8) {
            PhotosPicker(selection: $pickerItems, matching: .any(of: [.images, .videos])) {
                Label("Library", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(CardButtonStyle())
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button { showingCamera = true } label: {
                    Label("Camera", systemImage: "camera")
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(CardButtonStyle())
            }
        }
    }

    private func importPicked(_ item: PhotosPickerItem) async throws -> ExerciseMediaItem {
        if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
            guard let video = try await item.loadTransferable(type: PickedVideo.self) else { throw ExerciseMediaStore.StoreError.exportFailed }
            return try await ExerciseMediaStore.saveVideo(from: video.url)
        }
        guard let data = try await item.loadTransferable(type: Data.self) else { throw ExerciseMediaStore.StoreError.unreadableImage }
        // Decoding, resizing and JPEG-encoding a camera-roll photo is too heavy for the main actor.
        return try await Task.detached(priority: .userInitiated) { try ExerciseMediaStore.savePhoto(data) }.value
    }

    private func run(_ work: @escaping () async throws -> ExerciseMediaItem) {
        importing += 1
        failure = nil
        Task {
            defer { importing -= 1 }
            do {
                let item = try await work()
                session?.record(item)
                items.append(item)
            } catch {
                failure = "Couldn't add that file. Try another photo or video."
            }
        }
    }
}

struct ExerciseMediaThumbnail: View {
    let item: ExerciseMediaItem
    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Color(.systemGray5)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else if isLoading {
                    ProgressView()
                }
            }
            .overlay(alignment: .bottomLeading) {
                if item.kind == .video {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .padding(6)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .task(id: item) {
                guard image == nil, !isLoading else { return }
                isLoading = true
                defer { isLoading = false }
                image = await ExerciseMediaStore.thumbnail(for: item)
            }
            .accessibilityLabel(item.kind == .video ? "Video" : "Photo")
    }
}
