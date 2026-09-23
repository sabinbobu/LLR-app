import SwiftUI

struct SetTableMockup: View {
    private let rows: [(label: String, kg: String, reps: String, done: Bool)] = [
        ("W", "20", "10", true),
        ("1", "40", "8", false),
        ("2", "40", "8", false),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: "dumbbell.fill")
                    .font(.title3)
                    .frame(width: 52, height: 52)
                    .overlay(Circle().stroke(Theme.border))
                Text("Bench Press (Barbell)")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
            }
            Text("Felt strong today — bar speed was great.")
            Label("Rest Timer: 2min 30s", systemImage: "timer")
                .foregroundStyle(Theme.accent)
            VStack(spacing: 0) {
                row("SET", "KG", "REPS", check: nil, header: true)
                ForEach(rows.indices, id: \.self) { i in
                    let r = rows[i]
                    row(r.label, r.kg, r.reps, check: r.done, header: false)
                        .background(r.done ? Theme.completedRow : (i.isMultiple(of: 2) ? Theme.card : .clear))
                }
            }
            .padding(.horizontal, -20)
        }
    }

    private func row(_ set: String, _ kg: String, _ reps: String, check: Bool?, header: Bool) -> some View {
        HStack {
            Text(set)
                .foregroundStyle(set == "W" ? .orange : .primary)
                .frame(maxWidth: .infinity)
            Text(kg).frame(maxWidth: .infinity)
                .foregroundStyle(header || check == true ? .primary : .secondary)
            Text(reps).frame(maxWidth: .infinity)
                .foregroundStyle(header || check == true ? .primary : .secondary)
            Group {
                if let check {
                    Image(systemName: "checkmark")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(check ? Theme.completedCheck : Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "checkmark")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .font(header ? .caption : .title3)
        .foregroundStyle(header ? .secondary : .primary)
        .frame(height: header ? 36 : 56)
    }
}
