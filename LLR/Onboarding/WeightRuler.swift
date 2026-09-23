import SwiftUI

struct WeightRuler: View {
    @Binding var tenths: Int
    let range: ClosedRange<Int>

    @State private var position: Int?
    private let tickSpacing: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .bottom, spacing: 0) {
                    ForEach(range, id: \.self) { value in
                        tick(for: value)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, geo.size.width / 2 - tickSpacing / 2, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $position, anchor: .center)
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: 3, height: 110)
            }
            .mask(
                LinearGradient(
                    stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.2),
                            .init(color: .black, location: 0.8), .init(color: .clear, location: 1)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
        }
        .frame(height: 120)
        .onAppear { position = tenths }
        .onChange(of: position) { _, new in
            if let new { tenths = new }
        }
        .sensoryFeedback(.selection, trigger: position)
    }

    private func tick(for value: Int) -> some View {
        let isMajor = value % 10 == 0
        return VStack(spacing: 8) {
            Text(isMajor ? "\(value / 10)" : " ")
                .font(.body)
                .fixedSize()
            Rectangle()
                .fill(Color(.systemGray3))
                .frame(width: isMajor ? 2 : 1, height: isMajor ? 60 : 36)
        }
        .frame(width: tickSpacing, height: 110, alignment: .bottom)
    }
}
