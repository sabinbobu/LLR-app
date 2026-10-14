import SwiftUI

/// Age, Height, Sessions and Streak: one row of equal columns, or a 2 x 2 grid at accessibility sizes.
struct ProfileStatsRow: View {
    struct Item: Identifiable {
        let label: String
        let value: String
        let suffix: String?
        var id: String { label }
    }

    let items: [Item]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            grid
        } else {
            row
        }
    }

    private var row: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle().fill(Theme.heroDivider).frame(width: 1).padding(.vertical, 4)
                }
                stat(item)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var grid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(Array(items.prefix(2))) { item in stat(item) }
            }
            HStack(spacing: 0) {
                ForEach(Array(items.dropFirst(2))) { item in stat(item) }
            }
        }
    }

    private func stat(_ item: Item) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(item.value)
                    .font(.system(.title3, design: .monospaced).weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let suffix = item.suffix {
                    Text(suffix).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Text(item.label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
