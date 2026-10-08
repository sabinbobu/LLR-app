import Foundation

extension Progression {
    /// A target nobody can audit is one they stop trusting, so every plan can say what it saw.
    static func why(_ plan: Plan?, config: Config, unit: WeightUnit) -> String {
        let reps = config.range.upperBound
        func weight(_ kg: Double) -> String { "\(unit.format(kg: kg)) \(unit.rawValue)" }
        switch plan {
        case nil:
            return "No working sets logged yet — this session sets the baseline."
        case .addTime(let seconds):
            return "Held every set last time: +\(seconds) s."
        case .addLoad(let step):
            let change = config.assisted ? "\(weight(step)) less help" : "+\(weight(step))"
            switch config.rule {
            case .double: return "Every set hit \(reps) last time: \(change), back to \(config.range.lowerBound) reps."
            case .greyskull where step > config.incrementKg: return "Last set doubled its \(reps) reps: \(change)."
            case .greyskull: return "Last set reached \(reps) reps: \(change)."
            case .linear, .time: return "Every set hit \(reps) reps last time: \(change)."
            }
        case .addReps:
            return config.rule == .double
                ? "Same weight, one more rep per set until each reaches \(reps)."
                : "No load to add: one more rep per set."
        case .hold:
            return "Came up short last time: same weight, \(reps) reps a set."
        case .deload(let toKg, let stalls):
            let target = config.assisted ? "take \(weight(toKg)) of help" : "back off to \(weight(toKg))"
            return stalls == 1
                ? "Last set came up short: \(target) and build up again."
                : "Came up short \(stalls) sessions in a row: \(target) and build up again."
        }
    }

    static func title(_ config: Config?) -> String {
        guard let config else { return "Off" }
        switch config.rule {
        case .double: return "\(config.range.lowerBound)–\(config.range.upperBound) reps"
        case .linear: return "Linear, \(config.range.upperBound) reps"
        case .greyskull: return "Greyskull LP"
        case .time: return "+\(holdStepSeconds) s a session"
        }
    }

    /// Steps offered beside the automatic one, in the unit the lifter loads in.
    static func stepChoicesKg(unit: WeightUnit) -> [Double] {
        switch unit {
        case .kg: [1.25, 2.5, 5, 10]
        case .lbs: [2.5, 5, 10, 20].map { $0 * WeightUnit.kgPerLb }
        }
    }
}
