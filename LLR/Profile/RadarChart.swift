import SwiftUI

/// A 12-axis spider chart of sets per muscle group, normalized against the busiest axis so the shape
/// always fills the available room. Swift Charts has no radar mark, hence the hand-rolled `Canvas`.
struct RadarChart: View {
    let values: [MuscleGroup.RadarAxis: Int]

    private let axes = MuscleGroup.RadarAxis.allCases
    private var maxValue: Double { max(1, Double(values.values.max() ?? 0)) }

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 28
            let ringColor = Color(.systemGray5)

            for ring in 1...4 {
                context.stroke(webPath(center: center, radius: radius * CGFloat(ring) / 4), with: .color(ringColor), lineWidth: 1)
            }
            for index in axes.indices {
                var spoke = Path()
                spoke.move(to: center)
                spoke.addLine(to: point(center: center, radius: radius, index: index))
                context.stroke(spoke, with: .color(ringColor), lineWidth: 1)
            }

            var shape = Path()
            for (index, axis) in axes.enumerated() {
                let fraction = CGFloat(Double(values[axis] ?? 0) / maxValue)
                let p = point(center: center, radius: radius * fraction, index: index)
                index == 0 ? shape.move(to: p) : shape.addLine(to: p)
            }
            shape.closeSubpath()
            context.fill(shape, with: .color(Theme.accent.opacity(0.35)))
            context.stroke(shape, with: .color(Theme.accent), lineWidth: 2)
        }
        .overlay(labels)
        .aspectRatio(1, contentMode: .fit)
    }

    private var labels: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 10
            ForEach(Array(axes.enumerated()), id: \.offset) { index, axis in
                Text(axis.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(point(center: center, radius: radius, index: index))
            }
        }
    }

    private func webPath(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        for index in axes.indices {
            let p = point(center: center, radius: radius, index: index)
            index == 0 ? path.move(to: p) : path.addLine(to: p)
        }
        path.closeSubpath()
        return path
    }

    private func point(center: CGPoint, radius: CGFloat, index: Int) -> CGPoint {
        let angle = (Double(index) / Double(axes.count)) * 2 * .pi - .pi / 2
        return CGPoint(x: center.x + radius * CGFloat(cos(angle)), y: center.y + radius * CGFloat(sin(angle)))
    }
}
