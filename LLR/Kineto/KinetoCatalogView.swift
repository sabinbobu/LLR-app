import SwiftData
import SwiftUI

/// Browses the Kineto catalog, grouped Stability & endurance / Mobility / Walking. In `.pick`
/// mode, opening an exercise lets you add it at a chosen dosing level instead of just reading
/// about it; picking always goes through this catalog, never `ExercisePickerView`, which lists
/// exercises the catalog deliberately excludes (e.g. Sit Up, Superman).
struct KinetoCatalogView: View {
    enum Mode {
        case browse
        case pick(onPick: (Exercise, KinetoCatalog.Level) -> Void)
    }

    let mode: Mode
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var category: KinetoCatalog.Category?
    @State private var inspecting: KinetoCatalog.Exercise?

    private var isPicking: Bool {
        if case .pick = mode { return true }
        return false
    }

    private var byName: [String: Exercise] { RoutineLibrary.exercisesByName(in: context) }

    private var filtered: [KinetoCatalog.Exercise] {
        KinetoCatalog.exercises.filter { category == nil || $0.category == category }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    categoryPills
                    ForEach(KinetoCatalog.Category.allCases) { section in
                        let inSection = filtered.filter { $0.category == section }
                        if !inSection.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section.title).sectionLabel()
                                VStack(spacing: 0) {
                                    ForEach(Array(inSection.enumerated()), id: \.element.id) { index, exercise in
                                        Button { inspecting = exercise } label: { row(exercise) }
                                            .buttonStyle(.plain)
                                        if index < inSection.count - 1 { Divider().padding(.leading, 16) }
                                    }
                                }
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background)
            .navigationTitle(isPicking ? "Add Exercise" : "Kineto Catalog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isPicking {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                }
            }
            .sheet(item: $inspecting) { exercise in
                NavigationStack {
                    KinetoExerciseDetailView(exercise: exercise, onAdd: onAdd(for: exercise))
                }
            }
        }
    }

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pill("All", isSelected: category == nil) { category = nil }
                ForEach(KinetoCatalog.Category.allCases) { option in
                    pill(option.title, isSelected: category == option) { category = option }
                }
            }
        }
        .scrollClipDisabled()
    }

    private func pill(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(isSelected ? Theme.accent : Theme.surface, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.clear : Color(.systemGray4)))
        }
        .buttonStyle(.plain)
    }

    private func row(_ exercise: KinetoCatalog.Exercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name).font(.subheadline.weight(.medium))
                Text(exercise.direction.title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func onAdd(for exercise: KinetoCatalog.Exercise) -> ((KinetoCatalog.Level) -> Void)? {
        guard case .pick(let onPick) = mode, let real = byName[exercise.name] else { return nil }
        return { level in
            onPick(real, level)
            dismiss()
        }
    }
}
