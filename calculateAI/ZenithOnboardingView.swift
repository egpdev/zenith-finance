import SwiftUI

struct ZenithOnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0

    let pages = [
        OnboardingPage(
            image: "sparkles",
            title: "Welcome to Zenith",
            description:
                "Experience the next evolution of personal finance. AI-powered tracking, beautiful insights, and total control."
        ),
        OnboardingPage(
            image: "mic.fill",
            title: "Just Say It",
            description:
                "Forget typing. Just tell Zenith what you spent, and our AI Voice Assistant handles the rest instantly."
        ),
        OnboardingPage(
            image: "doc.viewfinder",
            title: "Scan & Go",
            description:
                "Point your camera at any receipt. Zenith extracts the details, categorizes the expense, and updates your budget."
        ),
    ]

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            // Background ambient glow
            Circle()
                .fill(Color.neonTurquoise.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(y: -200)

            VStack {
                Spacer()

                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 24) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.neonTurquoise.opacity(0.2),
                                                Color.mintGreen.opacity(0.1),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 160, height: 160)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )

                                Image(systemName: pages[index].image)
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: .neonTurquoise.opacity(0.3), radius: 20)

                            // Text
                            VStack(spacing: 12) {
                                Text(pages[index].title)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Text(pages[index].description)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 32)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 450)

                Spacer()

                // Controls
                VStack(spacing: 32) {
                    // Custom Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(
                                    currentPage == index
                                        ? Color.mintGreen : Color.white.opacity(0.2)
                                )
                                .frame(width: currentPage == index ? 24 : 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }

                    // Button
                    Button(action: {
                        HapticManager.shared.medium()
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            // Force immediate update naturally
                            hasSeenOnboarding = true
                        }
                    }) {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.mintGreen, Color.neonTurquoise],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .mintGreen.opacity(0.5), radius: 10)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}

#Preview {
    ZenithOnboardingView()
}
