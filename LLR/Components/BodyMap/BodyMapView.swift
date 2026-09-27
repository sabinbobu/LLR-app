import SwiftUI

/// Front and back muscle silhouettes. `tint` receives the `MuscleGroup`(s) a drawn region maps to
/// (more than one when LLR tracks a region more finely than the source art, e.g. upper back also
/// covers lats) and returns the fill color, or nil for the neutral outline color.
struct BodyMapView: View {
    var tint: ([MuscleGroup]) -> Color?
    /// Called with the tapped point in the 0–1 normalized box of that side; nil keeps the map inert.
    var onTap: ((BodyMapSide, CGPoint) -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            side(.anterior)
            side(.posterior)
        }
    }

    private func side(_ side: BodyMapSide) -> some View {
        Canvas { context, size in
            for region in side.regions {
                let groups = BodyMapData.muscleGroups(for: region.muscle)
                let color = tint(groups) ?? Color(.systemGray4)
                for polygon in region.polygons {
                    context.fill(BodyMapHitTest.path(polygon, size: size), with: .color(color))
                }
            }
        }
        // The source SVG's viewBox is 1000×2000.
        .aspectRatio(0.5, contentMode: .fit)
        .overlay {
            if let onTap {
                GeometryReader { geo in
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(coordinateSpace: .local) { location in
                            onTap(side, CGPoint(x: location.x / geo.size.width, y: location.y / geo.size.height))
                        }
                }
            }
        }
    }
}
