import SwiftUI

struct SelectableCard<Leading: View>: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void
    let leading: Leading

    init(
        title: String,
        subtitle: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void,
        @ViewBuilder leading: () -> Leading = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
        self.leading = leading()
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                leading
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.title3)
                    if let subtitle {
                        Text(subtitle).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Theme.accent : Color(.systemGray4))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Theme.accent : Theme.border, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
