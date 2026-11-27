import Foundation

/// What a set row's text field writes back to the model. `Value` is what that field stores.
struct SetFieldEdit<Value> {
    /// Call when focus moves: the next keystroke starts a new edit.
    mutating func reset() {}
}

extension SetFieldEdit where Value == Double {
    mutating func weightKg(_ text: String, current: Double, unit: WeightUnit) -> Double {
        WeightUnit.parse(text).map(unit.toKg) ?? current
    }
}

extension SetFieldEdit where Value == Int {
    mutating func reps(_ text: String, current: Int) -> Int {
        InputLimits.count(text) ?? current
    }
}

extension SetFieldEdit where Value == Int? {
    // Only a real hold is written: one nil turns the whole card into weight × reps rows.
    mutating func holdSeconds(_ text: String, current: Int?) -> Int? {
        guard let value = InputLimits.count(text, max: InputLimits.maxSeconds), value > 0 else { return current }
        return value
    }
}

enum PlannedSetField {
    /// A routine's blank weight is deliberate ("decide on the day"), so it stores nil.
    static func weightKg(_ text: String, current: Double?, unit: WeightUnit) -> Double? {
        WeightUnit.parse(text).map(unit.toKg)
    }
}
