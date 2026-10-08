import SwiftUI

/// Two targets per row: the row toggles selection, the trailing info button opens the
/// exercise's details — so checking form never costs the user their selection.
struct ExercisePickerRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let onToggle: () -> Void
    let onInfo: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    ExerciseIconTile(size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(exercise.name)
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.primary)
                            if exercise.isFavourite {
                                Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow)
                                    .accessibilityLabel("Favourite")
                            }
                        }
                        Text(exercise.isCustom ? "\(exercise.detail) · Custom" : exercise.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    selectionMark
                }
                .padding(.leading, 16)
                .padding(.trailing, 4)
                .padding(.vertical, 10)
                .frame(minHeight: 64)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About \(exercise.name)")
            .padding(.trailing, 4)
        }
        .background(isSelected ? Theme.accent.opacity(0.04) : Color.clear)
    }

    private var selectionMark: some View {
        ZStack {
            if isSelected {
                Circle().fill(Theme.accent)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Circle().strokeBorder(Color(.systemGray3), lineWidth: 1.5)
            }
        }
        .frame(width: 26, height: 26)
        .accessibilityHidden(true)
    }
}
