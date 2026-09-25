import SwiftUI

/// Runs when Finish is tapped on a Kineto session: back/leg pain and symptom spread, captured
/// before the workout is marked finished. A flagged result (Ostelo 2008's ≥ 2-point change, or
/// spread) tells the user to raise it with their physiotherapist — the app never changes the plan.
struct PainCheckOutSheet: View {
    let model: ActiveWorkoutModel
    var onFinish: () -> Void
    @State private var backPain: Double
    @State private var legPain: Double
    @State private var symptomsSpread = false

    init(model: ActiveWorkoutModel, onFinish: @escaping () -> Void) {
        self.model = model
        self.onFinish = onFinish
        _backPain = State(initialValue: Double(model.workout.backPainBefore ?? 0))
        _legPain = State(initialValue: Double(model.workout.legPainBefore ?? 0))
    }

    private var flagged: Bool {
        KinetoPain.shouldFlag(
            backBefore: model.workout.backPainBefore, backAfter: Int(backPain),
            legBefore: model.workout.legPainBefore, legAfter: Int(legPain),
            symptomsSpread: symptomsSpread
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How's your pain now?").sectionLabel()
                        PainSlider(title: "Back pain", value: $backPain)
                        PainSlider(title: "Leg pain", value: $legPain)
                    }
                    Toggle("Symptoms spread further down my leg during this session", isOn: $symptomsSpread)
                        .font(.subheadline)
                        .padding(16)
                        .cardStyle()
                    if flagged {
                        Label(
                            "This is a meaningful change — discuss it with your physiotherapist before your next session.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(16)
                .padding(.bottom, 80)
            }
            .background(Theme.background)
            .navigationTitle("Check-out")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button("Finish Session") {
                    model.workout.backPainAfter = Int(backPain)
                    model.workout.legPainAfter = Int(legPain)
                    model.workout.symptomsSpread = symptomsSpread
                    model.finish()
                    onFinish()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            }
        }
        .interactiveDismissDisabled()
    }
}
