import SwiftUI

struct MultiSelectList: View {
    let title: String
    let options: [String]
    @Binding var selection: [String]

    var body: some View {
        List(options, id: \.self) { option in
            Button {
                if let index = selection.firstIndex(of: option) {
                    selection.remove(at: index)
                } else {
                    selection.append(option)
                }
            } label: {
                HStack {
                    Text(option).foregroundStyle(.primary)
                    Spacer()
                    if selection.contains(option) {
                        Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
