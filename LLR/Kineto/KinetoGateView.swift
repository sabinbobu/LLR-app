import SwiftUI

/// First-use (and post-catalog-update) gate: three steps ending in a physiotherapist-clearance
/// checkbox. Nothing else in Kineto is reachable until this completes (Apple 1.4.1; AAOS — "unless
/// otherwise specified by your doctor or physical therapist"; CUH leaves dosing for the physio to set).
struct KinetoGateView: View {
    var onComplete: () -> Void
    @AppStorage(StorageKey.kinetoClearedVersion) private var clearedVersion = 0
    @AppStorage(StorageKey.kinetoClearedAt) private var clearedAt: Double = 0
    @AppStorage(StorageKey.kinetoDirection) private var directionRaw = KinetoDirectionPreference.notAssessed.rawValue
    @AppStorage(StorageKey.kinetoPainRule) private var painRuleRaw = KinetoPainRule.stopOnPain.rawValue
    @State private var step: Step = .whatItIs
    @State private var physioConfirmed = false

    private enum Step { case whatItIs, redFlags, setup }

    private var direction: Binding<KinetoDirectionPreference> {
        Binding(
            get: { KinetoDirectionPreference(rawValue: directionRaw) ?? .notAssessed },
            set: { directionRaw = $0.rawValue }
        )
    }

    private var painRule: Binding<KinetoPainRule> {
        Binding(
            get: { KinetoPainRule(rawValue: painRuleRaw) ?? .stopOnPain },
            set: { painRuleRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .whatItIs: whatItIs
                case .redFlags: redFlags
                case .setup: setup
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }

    private var whatItIs: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("About Kineto").font(.title2.bold())
                point(
                    icon: "checkmark.circle.fill", color: .green,
                    text: "A small, cited catalog of low-load exercises used in back-care programmes, and a place to log sessions and pain."
                )
                point(
                    icon: "xmark.circle.fill", color: .red,
                    text: "Not a diagnosis, not a treatment plan, and not a substitute for your physiotherapist. It doesn't decide what you should do."
                )
                point(
                    icon: "person.fill.checkmark", color: Theme.accent,
                    text: "Everything here should be reviewed and approved by your physiotherapist before you use it."
                )
            }
            .padding(16)
            .padding(.bottom, 80)
        }
        .safeAreaInset(edge: .bottom) { continueBar { step = .redFlags } }
    }

    private var redFlags: some View {
        VStack(spacing: 0) {
            RedFlagsView(mode: .info)
            continueBar { step = .setup }
        }
    }

    private var setup: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Setup").font(.title2.bold())

                VStack(alignment: .leading, spacing: 8) {
                    Text("Which direction helps your back?").sectionLabel()
                    Text("Ask your physiotherapist if you're not sure. This only adds a warning to exercises in the other direction — it never hides them.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    directionMenu
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Pain rule during exercise").sectionLabel()
                    PillToggle(options: KinetoPainRule.allCases, selection: painRule) { $0.title }
                }

                Button {
                    physioConfirmed.toggle()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: physioConfirmed ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundStyle(physioConfirmed ? Theme.accent : Color(.systemGray3))
                        Text("My physiotherapist has reviewed the exercises I will do.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .padding(.bottom, 80)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Continue") {
                clearedVersion = KinetoCatalog.version
                clearedAt = Date.now.timeIntervalSince1970
                onComplete()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!physioConfirmed)
            .padding()
        }
    }

    private var directionMenu: some View {
        Menu {
            ForEach(KinetoDirectionPreference.allCases) { option in
                Button(option.title) { direction.wrappedValue = option }
            }
        } label: {
            HStack {
                Text(direction.wrappedValue.title)
                Spacer()
                Image(systemName: "chevron.down").font(.caption.weight(.bold))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.field, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func point(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(color).font(.title3)
            Text(text).font(.subheadline)
        }
    }

    private func continueBar(action: @escaping () -> Void) -> some View {
        Button("Continue", action: action)
            .buttonStyle(PrimaryButtonStyle())
            .padding()
            .background(.bar)
    }
}
