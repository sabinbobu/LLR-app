import SwiftUI

struct GoalStep: View {
    @AppStorage(StorageKey.goal) private var goal: TrainingGoal?
    let next: () -> Void

    var body: some View {
        OnboardingScaffold(title: "What is your top goal?", canContinue: goal != nil, onContinue: next) {
            VStack(spacing: 16) {
                ForEach(TrainingGoal.allCases) { option in
                    SelectableCard(title: option.title, isSelected: goal == option, action: { goal = option }) {
                        Image(systemName: option.icon)
                            .font(.title2)
                            .frame(width: 36)
                    }
                }
            }
        }
    }
}
