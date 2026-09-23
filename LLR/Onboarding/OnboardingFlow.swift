import SwiftUI

enum OnboardingStep: Hashable {
    case gender, birthday, weight, height, goal, experience, welcome
}

struct OnboardingFlow: View {
    @AppStorage(StorageKey.hasOnboarded) private var hasOnboarded = false
    @State private var path: [OnboardingStep] = []

    var body: some View {
        NavigationStack(path: $path) {
            UnitsStep { path.append(.gender) }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: OnboardingStep.self) { step in
                    destination(for: step)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
    }

    @ViewBuilder
    private func destination(for step: OnboardingStep) -> some View {
        switch step {
        case .gender: GenderStep { path.append(.birthday) }
        case .birthday: BirthdayStep { path.append(.weight) }
        case .weight: BodyWeightStep { path.append(.height) }
        case .height: HeightStep { path.append(.goal) }
        case .goal: GoalStep { path.append(.experience) }
        case .experience: ExperienceStep { path.append(.welcome) }
        case .welcome: WelcomeCarousel { hasOnboarded = true }
        }
    }
}
