import SwiftUI

struct PillToggle<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.snappy) { selection = option }
                } label: {
                    Text(title(option))
                        .font(.title3)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(selection == option ? Color.white : Color.primary)
                        .background {
                            if selection == option {
                                RoundedRectangle(cornerRadius: 10).fill(Theme.accent)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1.5))
    }
}
