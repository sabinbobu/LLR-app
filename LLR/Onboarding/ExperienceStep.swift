import SwiftUI

struct ExperienceStep: View {
    @AppStorage(StorageKey.experience) private var experience: Experience?
    let next: () -> Void

    var body: some View {
        OnboardingScaffold(
            title: "How much training experience do you have?",
            canContinue: experience != nil,
            onContinue: next
        ) {
            VStack(spacing: 16) {
                ForEach(Experience.allCases) { option in
                    SelectableCard(
                        title: option.title,
                        subtitle: option.detail,
                        isSelected: experience == option,
                        action: { experience = option }
                    )
                }
            }
        }
    }
}
