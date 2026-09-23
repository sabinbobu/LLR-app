import SwiftUI

struct HeightStep: View {
    @AppStorage(StorageKey.heightUnit) private var unit: HeightUnit = .cm
    @AppStorage(StorageKey.heightCm) private var heightCm = 170
    let next: () -> Void

    private var totalInches: Int { Int((Double(heightCm) / 2.54).rounded()) }

    private func setInches(feet: Int, inches: Int) {
        heightCm = Int((Double(feet * 12 + inches) * 2.54).rounded())
    }

    private var feet: Binding<Int> {
        Binding(get: { totalInches / 12 }, set: { setInches(feet: $0, inches: totalInches % 12) })
    }

    private var inches: Binding<Int> {
        Binding(get: { totalInches % 12 }, set: { setInches(feet: totalInches / 12, inches: $0) })
    }

    var body: some View {
        OnboardingScaffold(title: "What is your height?", showsPrivacyNote: true, onContinue: next) {
            VStack {
                PillToggle(options: HeightUnit.allCases, selection: $unit) { $0.title }
                Spacer(minLength: 0)
                if unit == .cm {
                    Picker("Height", selection: $heightCm) {
                        ForEach(100...250, id: \.self) { Text("\($0) cm").tag($0) }
                    }
                    .pickerStyle(.wheel)
                } else {
                    HStack(spacing: 0) {
                        Picker("Feet", selection: feet) {
                            ForEach(3...8, id: \.self) { Text("\($0) ft").tag($0) }
                        }
                        Picker("Inches", selection: inches) {
                            ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                        }
                    }
                    .pickerStyle(.wheel)
                }
                Spacer(minLength: 0)
            }
        }
    }
}
