import SwiftUI

/// Persistent, non-dismissable disclaimer for every Kineto screen (Apple 1.4.1: a medical-content
/// app must remind users to check with a professional).
struct KinetoBanner: View {
    @State private var showingRedFlags = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Not medical advice. Only do exercises your physiotherapist approved.")
                .font(.footnote)
            Button("Red flags — when to stop and get help") { showingRedFlags = true }
                .font(.footnote.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingRedFlags) {
            NavigationStack { RedFlagsView(mode: .info) }
        }
    }
}
