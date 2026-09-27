import SwiftUI

/// Before/after with a draggable divider: the difference between two photos is easier to see when
/// they occupy the same frame than when they sit side by side.
struct PhotoCompareView: View {
    let photos: [ProgressPhoto]
    let trend: [WeightTrend.Point]
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @State private var beforeID: UUID?
    @State private var afterID: UUID?
    @State private var split: CGFloat = 0.5
    @State private var sideBySide = false

    private var oldestFirst: [ProgressPhoto] { photos.sorted { $0.takenAt < $1.takenAt } }
    private var before: ProgressPhoto? { oldestFirst.first { $0.id == beforeID } ?? oldestFirst.first }
    private var after: ProgressPhoto? { oldestFirst.first { $0.id == afterID } ?? oldestFirst.last }

    var body: some View {
        VStack(spacing: 16) {
            if let before, let after {
                Group {
                    if sideBySide {
                        HStack(spacing: 4) {
                            image(before).overlay(alignment: .bottomLeading) { caption(before) }
                            image(after).overlay(alignment: .bottomTrailing) { caption(after) }
                        }
                    } else {
                        slider(before, after)
                    }
                }
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            HStack {
                picker("Before", selection: $beforeID, fallback: before?.id)
                picker("After", selection: $afterID, fallback: after?.id)
            }
        }
        .padding()
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button { withAnimation(.snappy) { sideBySide.toggle() } } label: {
                Image(systemName: sideBySide ? "slider.horizontal.below.square.and.square.filled" : "square.split.2x1")
            }
            .accessibilityLabel(sideBySide ? "Show slider" : "Show side by side")
        }
    }

    private func slider(_ before: ProgressPhoto, _ after: ProgressPhoto) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                image(after)
                image(before)
                    .mask(alignment: .leading) { Rectangle().frame(width: geo.size.width * split) }
                Capsule().fill(.white).frame(width: 3).shadow(radius: 3)
                    .overlay(Image(systemName: "arrow.left.and.right").font(.caption.bold()).padding(8)
                        .background(.white, in: Circle()).foregroundStyle(.black))
                    .offset(x: geo.size.width * split - 1.5)
            }
            .overlay(alignment: .bottomLeading) { caption(before) }
            .overlay(alignment: .bottomTrailing) { caption(after) }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { split = min(max($0.location.x / geo.size.width, 0), 1) })
            .accessibilityElement()
            .accessibilityLabel("Before and after comparison")
            .accessibilityAdjustableAction { direction in
                split = min(max(split + (direction == .increment ? 0.1 : -0.1), 0), 1)
            }
        }
    }

    private func image(_ photo: ProgressPhoto) -> some View {
        Color(.systemGray6).overlay {
            if let uiImage = UIImage(data: photo.imageData) { Image(uiImage: uiImage).resizable().scaledToFill() }
        }
        .clipped()
    }

    private func caption(_ photo: ProgressPhoto) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(photo.takenAt.formatted(date: .abbreviated, time: .omitted)).font(.caption.weight(.semibold))
            if let kg = WeightTrend.trend(on: photo.takenAt, in: trend) {
                Text("\(unit.format(kg: kg)) \(unit.rawValue) trend").font(.caption2)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding(10)
    }

    private func picker(_ title: String, selection: Binding<UUID?>, fallback: UUID?) -> some View {
        Menu {
            ForEach(oldestFirst) { photo in
                Button(photo.takenAt.formatted(date: .abbreviated, time: .omitted)) { selection.wrappedValue = photo.id }
            }
        } label: {
            VStack(spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(oldestFirst.first { $0.id == (selection.wrappedValue ?? fallback) }?.takenAt
                    .formatted(date: .abbreviated, time: .omitted) ?? "—")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
