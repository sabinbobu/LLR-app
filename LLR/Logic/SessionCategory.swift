import Foundation
import SwiftUI

/// A colour label for the training split. It is not a `WorkoutSection`: that one scopes history and
/// prefill, this one must never change what a workout counts toward.
enum SessionCategory: String, CaseIterable, Identifiable {
    case none = ""
    case push, pull, legs, yoga

    var id: String { rawValue }

    /// Unknown stored text (a future category, a typo in an import) reads as uncategorised.
    init(raw: String) { self = SessionCategory(rawValue: raw) ?? .none }

    var title: String {
        switch self {
        case .none: "None"
        case .push: "Push"
        case .pull: "Pull"
        case .legs: "Legs"
        case .yoga: "Yoga"
        }
    }

    /// System colours adapt to light and dark and stay distinct from each other.
    var color: Color {
        switch self {
        case .none: .gray
        case .push: .orange
        case .pull: .blue
        case .legs: .green
        case .yoga: .purple
        }
    }

    static var choices: [SessionCategory] { allCases.filter { $0 != .none } }

    /// Only whole words count, and a name that mentions two categories ("Push/Pull") maps to none.
    static func infer(fromDayName name: String) -> SessionCategory {
        let words = Set(name.lowercased().split { !$0.isLetter }.map(String.init))
        let hits = [
            words.contains("push") ? SessionCategory.push : nil,
            words.contains("pull") ? .pull : nil,
            (words.contains("legs") || words.contains("leg")) ? .legs : nil,
            words.contains("yoga") ? .yoga : nil,
        ].compactMap { $0 }
        return hits.count == 1 ? hits[0] : .none
    }
}

struct CategoryChip: View {
    let category: SessionCategory

    var body: some View {
        if category != .none {
            Text(category.title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(category.color.opacity(0.18), in: Capsule())
                .foregroundStyle(category.color)
        }
    }
}

struct CategoryPicker: View {
    @Binding var category: SessionCategory

    var body: some View {
        Picker("Category", selection: $category) {
            ForEach(SessionCategory.allCases) { Text($0.title).tag($0) }
        }
    }
}
