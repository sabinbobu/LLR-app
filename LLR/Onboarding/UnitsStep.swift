import SwiftUI

struct UnitsStep: View {
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    let next: () -> Void

    var body: some View {
        OnboardingScaffold(title: "Select Units", showsBack: false, onContinue: next) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Weight")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                PillToggle(options: WeightUnit.allCases, selection: $unit) { $0.rawValue }
            }
        }
    }
}
