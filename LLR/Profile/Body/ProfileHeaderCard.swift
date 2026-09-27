import SwiftData
import SwiftUI

struct ProfileHeaderCard: View {
    let workoutCount: Int
    let avatar: UIImage?
    @AppStorage(StorageKey.displayName) private var name = ""
    @AppStorage(StorageKey.birthday) private var birthday: Double = 820_454_400
    @AppStorage(StorageKey.heightCm) private var heightCm = 170
    @AppStorage(StorageKey.goal) private var goal: TrainingGoal?
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @Query(filter: #Predicate<BodyMeasurement> { $0.kindRaw == "height" }, sort: \BodyMeasurement.takenAt, order: .reverse)
    private var heights: [BodyMeasurement]

    /// The latest logged height wins over the onboarding answer, matching what the Body tiles use.
    private var height: Double { heights.first?.value ?? Double(heightCm) }

    private var age: Int {
        Calendar.current.dateComponents([.year], from: Date(timeIntervalSince1970: birthday), to: .now).year ?? 0
    }

    var body: some View {
        HStack(spacing: 16) {
            AvatarView(image: avatar, name: name, size: 76)
            VStack(alignment: .leading, spacing: 8) {
                Text(name.isEmpty ? "Add your name" : name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(name.isEmpty ? .secondary : .primary)
                FlowChips(items: [
                    "\(age) yrs",
                    "\(unit.formatLength(cm: height)) \(unit.lengthSuffix)",
                    goal?.title,
                    "\(workoutCount) workout\(workoutCount == 1 ? "" : "s")",
                ].compactMap { $0 })
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24))
        .contentShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct AvatarView: View {
    let image: UIImage?
    let name: String
    let size: CGFloat

    private var initials: String {
        let letters = name.split(separator: " ").prefix(2).compactMap(\.first)
        return letters.isEmpty ? "" : String(letters).uppercased()
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [Theme.accent, Theme.protein], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay {
                        if initials.isEmpty {
                            Image(systemName: "person.fill").font(.system(size: size * 0.42)).foregroundStyle(.white)
                        } else {
                            Text(initials).font(.system(size: size * 0.38, weight: .bold, design: .rounded)).foregroundStyle(.white)
                        }
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

/// Chips that wrap onto a second line instead of truncating on narrow widths or large text.
struct FlowChips: View {
    let items: [String]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) { chips }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) { ForEach(items.prefix(2), id: \.self, content: chip) }
                HStack(spacing: 6) { ForEach(items.dropFirst(2), id: \.self, content: chip) }
            }
        }
    }

    private var chips: some View { ForEach(items, id: \.self, content: chip) }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(Theme.field, in: Capsule())
    }
}
