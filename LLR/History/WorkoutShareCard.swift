import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

/// A fixed-size, LLR-branded card rendered off-screen for the Share sheet — nothing about it depends
/// on the presenting device's size class, so what's shared always looks the same.
struct WorkoutShareCard: View {
    let workout: Workout
    let recap: WorkoutRecap
    let unit: WeightUnit

    @State private var rendered: ShareableImage?

    var body: some View {
        VStack(spacing: 20) {
            if let rendered {
                Image(uiImage: rendered.uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                ShareLink(item: rendered, preview: SharePreview("LLR Workout", image: Image(uiImage: rendered.uiImage)))
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal)
            } else {
                ProgressView().frame(height: 200)
            }
            Spacer()
        }
        .padding()
        .task { render() }
    }

    @MainActor
    private func render() {
        let renderer = ImageRenderer(content: cardContent)
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            rendered = ShareableImage(uiImage: uiImage)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LLR").font(.headline.weight(.heavy)).foregroundStyle(Theme.accent)
            Text(workout.title).font(.title.bold()).foregroundStyle(.black)
            HStack(spacing: 24) {
                stat("Weight", "\(unit.format(kg: recap.volumeKg)) \(unit.rawValue)")
                stat("Duration", Format.duration(recap.duration))
                stat("Sets", "\(recap.setCount)")
            }
            BodyMapView { groups in WorkoutSummaryView.tint(groups, recap: recap) }
                .frame(height: 260)
        }
        .padding(24)
        .frame(width: 360)
        .background(Color.white)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline).foregroundStyle(.black)
        }
    }
}

/// Wraps the rendered card so `ShareLink` can hand it to the system share sheet as a PNG.
struct ShareableImage: Transferable {
    let uiImage: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.uiImage.pngData() ?? Data()
        }
    }
}
