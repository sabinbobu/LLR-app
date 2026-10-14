import Foundation

/// Atwater factors, so a manual entry can derive calories from macros the same way everywhere.
enum MacroEnergy {
    static func kcal(proteinG: Double, carbsG: Double, fatG: Double) -> Double {
        (proteinG * 4 + carbsG * 4 + fatG * 9).rounded()
    }
}
