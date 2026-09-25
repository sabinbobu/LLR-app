import SwiftUI

/// Browses the bundled programs by what they're for; a program opens its days to start or save.
struct ExploreRoutinesView: View {
    let canStart: Bool
    let onStart: (ProgramTemplate, ProgramTemplate.Day) -> Void
    @State private var goal: ProgramTemplate.Goal?
    @State private var level: String?
    @State private var gear: String?

    private var matching: [ProgramTemplate] {
        RoutineLibrary.programs.filter { program in
            (goal == nil || program.goal == goal)
                && (level == nil || program.level.title == level)
                && (gear == nil || program.equipment.title == gear)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                goalPills
                HStack(spacing: 8) {
                    FilterChip(title: "Level", options: ProgramTemplate.Level.allCases.map(\.title), selection: $level)
                    FilterChip(title: "Equipment", options: ProgramTemplate.Gear.allCases.map(\.title), selection: $gear)
                }
                let programs = matching
                if programs.isEmpty {
                    Text("No programs match these filters.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .cardStyle()
                }
                ForEach(ProgramTemplate.Goal.allCases) { section in
                    let inSection = programs.filter { $0.goal == section }
                    if !inSection.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.title).sectionLabel()
                            ForEach(inSection) { program in
                                NavigationLink {
                                    ProgramDetailView(program: program, canStart: canStart, onStart: onStart)
                                } label: {
                                    ProgramCard(program: program)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Theme.background)
        .navigationTitle("Explore Routines")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var goalPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pill("All", isSelected: goal == nil) { goal = nil }
                ForEach(ProgramTemplate.Goal.allCases) { option in
                    pill(option.title, isSelected: goal == option) { goal = option }
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
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
