import SwiftData
import SwiftUI

struct ProfileHeaderCard: View {
    /// Start dates of every finished lift and run, the same list the calendar screen reads.
    let starts: [Date]
    let avatar: UIImage?
    @AppStorage(StorageKey.displayName) private var name = ""
    @AppStorage(StorageKey.birthday) private var birthday: Double = 820_454_400
    @AppStorage(StorageKey.heightCm) private var heightCm = 170
    @AppStorage(StorageKey.goal) private var goal: TrainingGoal?
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @Query(filter: #Predicate<BodyMeasurement> { $0.kindRaw == "height" }, sort: \BodyMeasurement.takenAt, order: .reverse)
    private var heights: [BodyMeasurement]

    /// Local on purpose: the shared radius scale is being introduced separately.
    private let cornerRadius: CGFloat = 28

    /// The latest logged height wins over the onboarding answer, matching what the Body tiles use.
    private var height: Double { heights.first?.value ?? Double(heightCm) }

    private var age: Int {
        Calendar.current.dateComponents([.year], from: Date(timeIntervalSince1970: birthday), to: .now).year ?? 0
    }

    private var heightText: String { unit.formatLength(cm: height) }

    var body: some View {
        let summary = ProfileHeaderStats(starts: starts)
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                WeeklyRingAvatar(image: avatar, name: name, days: summary.weekDays)
                header
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.tertiary)
            }
            ProfileStatsRow(items: items(summary))
        }
        .padding(18)
        .background(surface)
        .overlay(highlight)
        .shadow(color: Theme.heroShadow, radius: 16, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken(summary))
        .accessibilityAddTraits(.isButton)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name.isEmpty ? "Add your name" : name)
                .font(.title.weight(.heavy))
                .foregroundStyle(name.isEmpty ? .secondary : .primary)
                .fixedSize(horizontal: false, vertical: true)
            if let goal {
                Text(goal.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.14), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var surface: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(LinearGradient(colors: [Theme.heroTint, Theme.surface], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var highlight: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(colors: [Theme.heroHighlight, Color.clear], startPoint: .top, endPoint: .center),
                lineWidth: 1
            )
    }

    private func items(_ summary: ProfileHeaderStats) -> [ProfileStatsRow.Item] {
        [
            ProfileStatsRow.Item(label: "Age", value: "\(age)", suffix: nil),
            ProfileStatsRow.Item(label: "Height", value: heightText, suffix: unit.lengthSuffix),
            ProfileStatsRow.Item(label: "Sessions", value: "\(summary.sessionCount)", suffix: nil),
            ProfileStatsRow.Item(label: "Streak", value: "\(summary.streak)", suffix: "wk"),
        ]
    }

    private func spoken(_ summary: ProfileHeaderStats) -> String {
        let unitWord: String = unit == .kg ? "centimetres" : "inches"
        return ProfileHeaderStats.spokenSummary(
            name: name, age: age, height: heightText, heightUnit: unitWord,
            goal: goal?.title, sessions: summary.sessionCount, streak: summary.streak)
    }
}
