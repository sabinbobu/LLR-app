import SwiftUI

/// Front and back muscle silhouettes. `tint` receives the `MuscleGroup`(s) a drawn region maps to
/// (more than one when LLR tracks a region more finely than the source art, e.g. upper back also
/// covers lats) and returns the fill color, or nil for the neutral outline color.
struct BodyMapView: View {
    var tint: ([MuscleGroup]) -> Color?

    var body: some View {
        HStack(spacing: 12) {
            side(BodyMapData.shared.anterior)
            side(BodyMapData.shared.posterior)
        }
    }

    private func side(_ regions: [BodyMapData.Region]) -> some View {
        Canvas { context, size in
            for region in regions {
                let groups = BodyMapData.muscleGroups(for: region.muscle)
                let color = tint(groups) ?? Color(.systemGray4)
                for polygon in region.polygons {
                    var path = Path()
                    for (index, point) in polygon.enumerated() {
                        let p = CGPoint(x: point[0] * size.width, y: point[1] * size.height)
                        if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
                    }
                    path.closeSubpath()
                    context.fill(path, with: .color(color))
                }
            }
        }
        // The source SVG's viewBox is 1000×2000.
        .aspectRatio(0.5, contentMode: .fit)
    }
}
