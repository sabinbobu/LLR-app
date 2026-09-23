import SwiftUI

struct GenderStep: View {
    @AppStorage(StorageKey.gender) private var gender: Gender?
    let next: () -> Void

    var body: some View {
        OnboardingScaffold(
            title: "What is your gender?",
            showsPrivacyNote: true,
            canContinue: gender != nil,
            onContinue: next
        ) {
            VStack(spacing: 16) {
                ForEach(Gender.allCases) { option in
                    SelectableCard(title: option.title, isSelected: gender == option, action: { gender = option }) {
                        Text(option.symbol)
                            .font(.system(size: 30))
                            .frame(width: 36)
                    }
                }
            }
        }
    }
}
