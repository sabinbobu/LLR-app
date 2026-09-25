import SwiftUI

/// The red-flag list, shown two ways: as information (the gate, and the banner's link) and,
/// doubling as the stop screen, after a check-in question is answered yes. Same content either
/// way, so the user learns it once and recognises it instantly when it matters. Content is
/// derived from NHS — Back pain and AAOS OrthoInfo — Herniated Disk in the Lower Back, not copied verbatim.
struct RedFlagsView: View {
    enum Mode: Equatable {
        case info
        case stop
    }

    let mode: Mode
    var onDone: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if mode == .stop {
                    stopHeader
                }
                group(
                    title: "Call emergency services or go to A&E",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    items: [
                        "Pain, tingling, weakness or numbness in both legs",
                        "Loss of feeling around your genitals or anus",
                        "New bladder or bowel changes",
                        "New changes in sexual function",
                        "Chest pain",
                        "Back pain after a serious accident",
                    ],
                    footer: "These can be signs of cauda equina syndrome, a medical emergency (AAOS)."
                )
                group(
                    title: "Contact your GP or call 111",
                    icon: "phone.fill",
                    color: .orange,
                    items: [
                        "Feeling hot, cold, shivery or generally unwell",
                        "Severe pain that starts suddenly or gets worse quickly",
                    ],
                    footer: nil
                )
                group(
                    title: "Stop the exercise and contact your physio",
                    icon: "figure.stand",
                    color: Theme.accent,
                    items: [
                        "Pain spreading further down one leg, or below the knee, during exercise",
                        "New numbness or weakness in one leg",
                    ],
                    footer: "Not on the NHS emergency list — a conservative design choice, based on the centralization principle (APTA 2012)."
                )
                Text("Source: NHS — Back pain · AAOS OrthoInfo — Herniated Disk in the Lower Back")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .padding(.bottom, mode == .stop ? 60 : 0)
        }
        .background(Theme.background)
        .navigationTitle(mode == .info ? "Red Flags" : "Stop")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if mode == .info {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if mode == .stop {
                Button("Done", action: onDone)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding()
            }
        }
    }

    private var stopHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session not started").font(.title2.bold())
            Text("You flagged one of the symptoms below. Don't do this session — get it checked first.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func group(title: String, icon: String, color: Color, items: [String], footer: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
            ForEach(items, id: \.self) { item in
                Label(item, systemImage: "circle.fill")
                    .labelStyle(BulletLabelStyle())
                    .font(.subheadline)
            }
            if let footer {
                Text(footer).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

private struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 8) {
            configuration.icon.font(.system(size: 5)).padding(.top, 6).foregroundStyle(.tertiary)
            configuration.title
        }
    }
}
