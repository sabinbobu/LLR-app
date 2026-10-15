import SwiftUI

/// A number field that writes through on every keystroke. `TextField(value:format:)` only commits a
/// non-string value on Return or when focus leaves, and the number pads have no Return key, so a
/// value typed right before tapping Save could be dropped.
struct NumberField: View {
    let title: String
    @Binding var value: Double?
    var fractionDigits = 1

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(fractionDigits > 0 ? .decimalPad : .numberPad)
            .focused($focused)
            .onAppear { text = NumberText.format(value, fractionDigits: fractionDigits) }
            .onChange(of: text) { _, new in
                if let parsed = NumberText.parse(new) { value = parsed }
            }
            // Changes from elsewhere show up, but never rewrite what the user is typing.
            .onChange(of: value) { _, new in
                if !focused { text = NumberText.format(new, fractionDigits: fractionDigits) }
            }
    }
}

extension NumberField {
    /// Empty reads as 0, for fields where blank and zero mean the same.
    init(_ title: String, value: Binding<Double>, fractionDigits: Int = 1) {
        self.init(title: title, value: Binding(get: { value.wrappedValue }, set: { value.wrappedValue = $0 ?? 0 }),
                  fractionDigits: fractionDigits)
    }

    init(_ title: String, value: Binding<Int?>) {
        self.init(title: title, value: Binding(get: { value.wrappedValue.map(Double.init) },
                                               set: { value.wrappedValue = $0.map { Int($0.rounded()) } }),
                  fractionDigits: 0)
    }
}

enum NumberText {
    /// `.some(nil)` for a cleared field, `nil` for text that isn't a number yet (e.g. "1,"), which
    /// leaves the last good value alone.
    static func parse(_ text: String) -> Double?? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .some(nil) }
        guard let value = WeightUnit.parse(trimmed), value.isFinite, value >= 0 else { return nil }
        return .some(value)
    }

    static func format(_ value: Double?, fractionDigits: Int) -> String {
        guard let value else { return "" }
        return value.formatted(.number.precision(.fractionLength(0...fractionDigits)).grouping(.never))
    }
}
