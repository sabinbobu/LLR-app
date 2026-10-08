import SwiftUI

/// The optional effort cell of a set row: one tap opens the presets, a second logs one.
struct EffortChip: View {
    @Binding var rir: Double?
    let scale: EffortScale

    static let width: CGFloat = 52

    var body: some View {
        Menu {
            Picker(scale.title, selection: $rir) {
                Text("Not rated").tag(Double?.none)
                ForEach(Effort.bands, id: \.rir) { band in
                    Text("\(Effort.text(rir: band.rir, scale: scale)) · \(band.feel)").tag(Optional(band.rir))
                }
            }
        } label: {
            Text(rir.map { Effort.text(rir: $0, scale: scale) } ?? "–")
                .font(.subheadline.weight(.semibold))
                // The text stays in the primary colour: white on the yellow and green bands is unreadable.
                .foregroundStyle(rir == nil ? Color.secondary : Color.primary)
                .frame(width: 40, height: 30)
                .background(fill, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(rir.map(Self.color) ?? Color.clear, lineWidth: 1.5))
                .frame(width: Self.width, height: 52)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Effort")
        .accessibilityValue(rir.map { "\(scale.title) \(Effort.text(rir: $0, scale: scale))" } ?? "Not rated")
    }

    private var fill: Color {
        rir.map { Self.color($0).opacity(0.25) } ?? Color(.systemGray5)
    }

    /// Runs from "nothing left" (purple, past red) to "easy" (teal), so a glance down a workout
    /// shows how hard it ran.
    static func color(_ rir: Double) -> Color {
        [Color.purple, .red, .orange, .yellow, .green, .teal][Effort.bandIndex(for: rir)]
    }
}
