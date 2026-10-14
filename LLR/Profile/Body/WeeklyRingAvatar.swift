import SwiftUI

/// The avatar wrapped in a seven-segment ring, one segment per day of the current week.
struct WeeklyRingAvatar: View {
    let image: UIImage?
    let name: String
    let days: [Bool]

    private let photoSize: CGFloat = 96
    private let stroke: CGFloat = 6
    private let inset: CGFloat = 6
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var outerSize: CGFloat { photoSize + 2 * (inset + stroke) }

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                segment(index)
            }
            AvatarView(image: image, name: name, size: photoSize)
        }
        .frame(width: outerSize, height: outerSize)
        .onAppear { appeared = true }
    }

    private func isFilled(_ index: Int) -> Bool {
        index < days.count && days[index]
    }

    /// Fraction of the circle each day owns, minus a gap so the seven arcs read as separate.
    private func range(_ index: Int) -> (from: CGFloat, to: CGFloat) {
        let slice: CGFloat = 1.0 / 7.0
        let gap: CGFloat = 0.018
        let start: CGFloat = CGFloat(index) * slice + gap / 2
        return (start, start + slice - gap)
    }

    private func segment(_ index: Int) -> some View {
        let bounds = range(index)
        let filled: Bool = isFilled(index)
        let end: CGFloat = (filled && appeared) ? bounds.to : bounds.from
        let animation: Animation? = reduceMotion ? nil : .easeOut(duration: 0.45).delay(Double(index) * 0.07)
        let style = StrokeStyle(lineWidth: stroke, lineCap: .butt)
        // Butt caps: a round cap would draw a dot at zero length before the fill animates in.
        return ZStack {
            Circle()
                .trim(from: bounds.from, to: bounds.to)
                .stroke(Theme.ringTrack, style: style)
            Circle()
                .trim(from: bounds.from, to: end)
                .stroke(Theme.accent, style: style)
                .animation(animation, value: appeared)
        }
        .rotationEffect(.degrees(-90))
        .padding(stroke / 2)
    }
}
