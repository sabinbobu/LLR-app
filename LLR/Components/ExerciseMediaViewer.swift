import AVKit
import SwiftUI

struct ExerciseMediaViewer: View {
    let item: ExerciseMediaItem
    /// Non-nil only inside an editor; a detail page just shows the media.
    var onDelete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    private var url: URL { ExerciseMediaStore.url(for: item.fileName) }

    var body: some View {
        NavigationStack {
            Group {
                switch item.kind {
                case .photo:
                    if let image = UIImage(contentsOfFile: url.path()) {
                        Image(uiImage: image).resizable().scaledToFit()
                    } else {
                        ContentUnavailableView("Photo missing", systemImage: "photo")
                    }
                case .video:
                    VideoPlayer(player: player)
                        .onAppear { player = AVPlayer(url: url); player?.play() }
                        .onDisappear { player?.pause() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                if let onDelete {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Remove")
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
