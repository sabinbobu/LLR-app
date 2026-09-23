import SwiftUI

/// One side of the bar, sleeve on the right; plates are sized by weight so the load reads at a glance.
struct BarbellDiagram: View {
    let perSide: [Double]
    let unit: WeightUnit

    var body: some View {
        let heaviest = PlateCalculator.plates(for: unit).max() ?? 1
        HStack(spacing: 2) {
            Rectangle()
                .fill(Color(.systemGray3))
                .frame(height: 10)
            Rectangle()
                .fill(Color(.systemGray2))
                .frame(width: 10, height: 36)
            ForEach(Array(perSide.enumerated()), id: \.offset) { _, plate in
                plateView(plate, heaviest: heaviest)
            }
            Rectangle()
                .fill(Color(.systemGray3))
                .frame(width: 44, height: 10)
        }
    }

    private func plateView(_ plate: Double, heaviest: Double) -> some View {
        let ratio: Double = max(0.3, plate / heaviest)
        let height: CGFloat = 140 * CGFloat(ratio)
        return RoundedRectangle(cornerRadius: 3)
            .fill(color(for: plate))
            .frame(width: ratio > 0.5 ? 16 : 10, height: height)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(.black.opacity(0.15)))
    }

    /// Competition colour coding (kg) so the diagram matches the plates on the gym floor.
    private func color(for plate: Double) -> Color {
        switch (unit, plate) {
        case (.kg, 25), (.lbs, 45): .red
        case (.kg, 20), (.lbs, 35): .blue
        case (.kg, 15), (.lbs, 25): .yellow
        case (.kg, 10), (.lbs, 10): .green
        case (.kg, 5), (.lbs, 5): Color(.systemGray5)
        default: Color(.darkGray)
        }
    }
}
