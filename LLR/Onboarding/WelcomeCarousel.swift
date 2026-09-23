import SwiftUI

struct WelcomeCarousel: View {
    let finish: () -> Void
    @State private var page = 0
    private let pageCount = 2

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button("Skip", action: finish)
                    .font(.title3)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground), in: Capsule())
                    .overlay(Capsule().stroke(Theme.border))
                    .shadow(color: .black.opacity(0.06), radius: 12)
            }
            .padding(.horizontal, 24)

            TabView(selection: $page) {
                WelcomePage(title: "Welcome to LLR!", subtitle: "Easily log your workouts, tracking each set.") {
                    SetTableMockup()
                }
                .tag(0)
                WelcomePage(title: "Measure progress", subtitle: "Watch every lift trend upward, session by session.") {
                    ProgressMockup()
                }
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 10) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Circle()
                        .fill(index == page ? Theme.accent : Color(.systemGray5))
                        .frame(width: 9, height: 9)
                }
            }

            Button("Continue") {
                if page < pageCount - 1 {
                    withAnimation { page += 1 }
                } else {
                    finish()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}
