import SwiftUI

/// A frozen illustration of the routine builder for RoutineHelpView — not live data, just the
/// four beats of the real screen (empty state, planned sets, notes, rest timer).
struct RoutinePlanMockup: View {
    enum Stage { case empty, sets, notes, restTimer }
    let stage: Stage

    private let rows: [(label: String, kg: String, reps: String)] = [
        ("W", "40", "8"), ("1", "50", "8"), ("2", "58", "6"), ("3", "58", "6"), ("4", "64", "4"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Chest and Shoulder Day 🏆").font(.headline)
            if stage == .empty {
                emptyState
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "dumbbell.fill")
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(Theme.border))
                    Text("Bench Press (Barbell)").foregroundStyle(Theme.accent)
                    Spacer()
                    Image(systemName: "ellipsis")
                }
                Text(stage == .notes || stage == .restTimer ? "Keep a tight grip on the bar at all times" : "Add routine notes here")
                    .foregroundStyle(stage == .notes || stage == .restTimer ? .primary : .secondary)
                Label("Rest Timer: \(stage == .restTimer ? "2min 30s" : "OFF")", systemImage: "timer")
                    .foregroundStyle(Theme.accent)
                setTable
            }
        }
        .overlay(alignment: .bottom) {
            if stage == .restTimer { restPopup.offset(y: 28) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell").font(.system(size: 36)).foregroundStyle(.secondary)
            Text("No exercises").font(.headline)
            Text("Get started by adding an exercise to your routine").font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var setTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("SET").frame(width: 40)
                Text("KG").frame(maxWidth: .infinity)
                Text("REPS").frame(maxWidth: .infinity)
            }
            .font(.caption2).foregroundStyle(.secondary)
            ForEach(rows.indices, id: \.self) { i in
                let visible = stage != .sets || i < 2
                HStack {
                    Text(rows[i].label).foregroundStyle(rows[i].label == "W" ? .orange : .primary).frame(width: 40)
                    Text(visible ? rows[i].kg : "-").frame(maxWidth: .infinity)
                    Text(visible ? rows[i].reps : "-").frame(maxWidth: .infinity)
                }
                .frame(height: 34)
                .background(i.isMultiple(of: 2) ? Theme.card : .clear)
            }
        }
        .font(.subheadline)
        .monospacedDigit()
    }

    private var restPopup: some View {
        HStack {
            Text("-15s").foregroundStyle(Theme.accent)
            Spacer()
            Text("2:25").font(.title3.weight(.semibold)).monospacedDigit()
            Spacer()
            Text("+15s").foregroundStyle(Theme.accent)
            Text("Skip")
                .padding(.horizontal, 12).padding(.vertical, 6)
                .foregroundStyle(.white)
                .background(Theme.accent, in: Capsule())
        }
        .font(.subheadline)
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        .padding(.horizontal, 8)
    }
}
