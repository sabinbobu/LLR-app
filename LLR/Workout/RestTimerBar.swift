import SwiftUI

struct RestTimerBar: View {
    let timer: RestTimer

    var body: some View {
        if let start = timer.startDate, let end = timer.endDate, start < end {
            VStack(spacing: 10) {
                ProgressView(timerInterval: start...end, countsDown: true) { EmptyView() } currentValueLabel: { EmptyView() }
                    .tint(Theme.accent)
                HStack {
                    Button("-15") { timer.adjust(by: -15) }
                        .buttonStyle(.bordered)
                    Spacer()
                    VStack(spacing: 0) {
                        Text("Rest").font(.caption).foregroundStyle(.secondary)
                        Text(timerInterval: start...end, countsDown: true)
                            .font(.title2.weight(.semibold).monospacedDigit())
                    }
                    Spacer()
                    Button("+15") { timer.adjust(by: 15) }
                        .buttonStyle(.bordered)
                    Button("Skip") { timer.skip() }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(.regularMaterial)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
