import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// SwiftUI's PhotosPicker only reads the library; taking a new photo still needs UIKit.
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    /// Non-nil turns on video recording alongside photos; the recorded file is a temporary copy.
    var videoURL: Binding<URL?>? = nil
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        if videoURL != nil {
            picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let url = info[.mediaURL] as? URL {
                // The picker's file is its own to clean up once it dismisses; take a copy the importer may delete.
                let copy = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).\(url.pathExtension)")
                parent.videoURL?.wrappedValue = (try? FileManager.default.copyItem(at: url, to: copy)) != nil ? copy : url
            } else {
                parent.image = info[.originalImage] as? UIImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
