import Foundation

enum PlateCalculator {
    struct Result: Equatable {
        let perSide: [Double]
        let loaded: Double
        /// Positive when the target can't be hit exactly with the available plates.
        let remainder: Double
    }

    static func plates(for unit: WeightUnit) -> [Double] {
        unit == .kg ? [25, 20, 15, 10, 5, 2.5, 1.25] : [45, 35, 25, 10, 5, 2.5]
    }

    static func defaultBar(for unit: WeightUnit) -> Double {
        unit == .kg ? 20 : 45
    }

    /// Greedy is optimal-enough for standard gym denominations and matches how people load a bar:
    /// biggest plates first. Math runs in integer hundredths so 1.25 kg steps never drift.
    static func load(target: Double, bar: Double, plates: [Double]) -> Result {
        let scale = 100.0
        var remaining = Int(((target - bar) / 2 * scale).rounded(.down))
        var perSide: [Double] = []
        if remaining > 0 {
            for plate in plates.sorted(by: >) {
                let size = Int((plate * scale).rounded())
                guard size > 0 else { continue }
                while remaining >= size {
                    perSide.append(plate)
                    remaining -= size
                }
            }
        }
        let loaded = bar + 2 * perSide.reduce(0, +)
        return Result(perSide: perSide, loaded: loaded, remainder: max(0, target - loaded))
    }
}
