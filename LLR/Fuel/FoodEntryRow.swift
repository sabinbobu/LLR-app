import SwiftUI

struct FoodEntryRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.name).font(.body.weight(.medium)).lineLimit(1)
                    if entry.source == .ai {
                        Image(systemName: "sparkles").font(.caption).foregroundStyle(Theme.accent)
                    }
                }
                HStack(spacing: 10) {
                    macro("P", entry.proteinG, Theme.protein)
                    macro("C", entry.carbsG, Theme.carbs)
                    macro("F", entry.fatG, Theme.fat)
                    if let grams = entry.grams {
                        Text("\(Int(grams)) g").foregroundStyle(.secondary)
                    }
                }
                .font(.caption.monospacedDigit())
            }
            Spacer()
            Text("\(Int(entry.kcal))")
                .font(.headline.monospacedDigit())
            + Text(" kcal").font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = entry.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            Image(systemName: entry.meal.icon)
                .frame(width: 44, height: 44)
                .background(Theme.field, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.secondary)
        }
    }

    private func macro(_ letter: String, _ grams: Double, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text("\(letter) \(Int(grams.rounded()))")
        }
    }
}
