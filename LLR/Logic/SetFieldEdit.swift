import Foundation

/// What a set row's text field writes back to the model. `Value` is what that field stores.
///
/// Fields save on every keystroke, so an edit remembers what it started from: deleting back through
/// "100" passes "10" and "1", and an emptied field must not leave one of those to be logged.
struct SetFieldEdit<Value> {
    private var original: Value?

    /// Call when focus moves: the next keystroke starts a new edit.
    mutating func reset() {
        original = nil
    }

    fileprivate mutating func value(for text: String, current: Value, typed: Value?) -> Value {
        if text.isEmpty { return original ?? current }
        guard let typed else { return current }
        if original == nil { original = current }
        return typed
    }
}

extension SetFieldEdit where Value == Double {
    mutating func weightKg(_ text: String, current: Double, unit: WeightUnit) -> Double {
        // The row fills the field with the stored weight rounded for display; reading that back
        // would turn 61.25 into 61.3.
        if text == unit.format(kg: current) { return current }
        return value(for: text, current: current, typed: WeightUnit.parse(text).map(unit.toKg))
    }
}

extension SetFieldEdit where Value == Int {
    mutating func reps(_ text: String, current: Int) -> Int {
        value(for: text, current: current, typed: InputLimits.count(text))
    }
}

extension SetFieldEdit where Value == Int? {
    // Only a real hold is written: one nil turns the whole card into weight × reps rows.
    mutating func holdSeconds(_ text: String, current: Int?) -> Int? {
        let seconds = InputLimits.count(text, max: InputLimits.maxSeconds).flatMap { $0 > 0 ? $0 : nil }
        return value(for: text, current: current, typed: seconds.map(Optional.some))
    }
}

enum PlannedSetField {
    /// A routine's blank weight is deliberate ("decide on the day"), so it stores nil.
    static func weightKg(_ text: String, current: Double?, unit: WeightUnit) -> Double? {
        if let current, text == unit.format(kg: current) { return current }
        return WeightUnit.parse(text).map(unit.toKg)
    }
}
