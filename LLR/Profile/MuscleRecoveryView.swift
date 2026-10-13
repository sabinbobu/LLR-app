import SwiftUI

struct MuscleRecoveryView: View {
    let workouts: [Workout]
    @State private var showingInfo = false

    private var statuses: [MuscleGroup: MuscleRecovery.Status] {
        MuscleRecoveryInput.statuses(for: workouts)
    }

    private var overall: Double { MuscleRecoveryInput.overall(for: workouts) }
    private var systemic: Double { MuscleRecoveryInput.systemicExhaustion(for: workouts) }

    private func rows(for region: MuscleGroup.Region) -> [MuscleRecovery.Status] {
        statuses.values
            .filter { $0.muscle.region == region }
            .sorted { $0.muscle.rawValue < $1.muscle.rawValue }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        RecoveryRing(percent: overall).frame(width: 100, height: 100)
                        if systemic >= 1 {
                            Label("Body \(Int(systemic))% exhausted from recent runs", systemImage: "figure.run")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .listRowSeparator(.hidden)
            }
            ForEach(MuscleGroup.Region.allCases) { region in
                let statuses = rows(for: region)
                if !statuses.isEmpty {
                    Section(region.rawValue) {
                        ForEach(statuses, id: \.muscle) { status in
                            row(status)
                        }
                    }
                }
            }
        }
        .navigationTitle("Muscle Recovery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingInfo = true
            } label: {
                Image(systemName: "info.circle")
            }
        }
        .sheet(isPresented: $showingInfo) { infoSheet }
    }

    private func row(_ status: MuscleRecovery.Status) -> some View {
        HStack(spacing: 14) {
            BodyMapView { groups in
                groups.contains(status.muscle) ? Theme.recoveryColor(status.percent) : nil
            }
            .frame(width: 40, height: 40)
            .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(status.muscle.rawValue)
                if let name = status.lastExerciseName, let date = status.lastTrained {
                    Text("\(date.formatted(.relative(presentation: .named))) · \(name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No recent exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(Int(status.percent))%")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Theme.recoveryColor(status.percent), in: Capsule())
        }
    }

    private var infoSheet: some View {
        NavigationStack {
            ScrollView {
                Text("""
                Recovery is an estimate, not a measurement. It fades a muscle's working-set and running load down \
                to zero over roughly 2–3 days, based on how much you trained it and how recently. It \
                doesn't know your sleep, nutrition, or how sore you actually feel — use it as a rough \
                guide for what to train next, not a hard rule.
                """)
                .padding()
            }
            .navigationTitle("About Recovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { showingInfo = false }
            }
        }
        .presentationDetents([.medium])
    }
}
