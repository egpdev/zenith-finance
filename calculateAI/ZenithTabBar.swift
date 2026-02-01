import SwiftUI

struct ZenithTabBar: View {
    @Binding var selectedTab: Int

    // Tab Items definition
    let tabs: [(image: String, label: String)] = [
        ("house.fill", "Dashboard"),
        ("list.bullet.rectangle.portrait.fill", "History"),
        ("calendar.badge.clock", "Planner"),
        ("person.fill", "Profile"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    if selectedTab != index {
                        HapticManager.shared.light()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].image)
                            .font(.system(size: 22))
                            .scaleEffect(selectedTab == index ? 1.1 : 1.0)

                        // Optional: Show label only if selected, or always?
                        // UX Analysis suggests clean. Let's keep it minimal.
                        // We can show a small dot or glow for selected.
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == index ? .mintGreen : .white.opacity(0.4))
                    .overlay(
                        // Glow effect for active tab
                        ZStack {
                            if selectedTab == index {
                                Circle()
                                    .fill(Color.mintGreen.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .blur(radius: 10)
                            }
                        }
                    )
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            Color.zenithBlack.opacity(0.8)
                .background(.ultraThinMaterial)
        )
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.1), .clear, .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
        .padding(.bottom, 10)  // Space from bottom edge
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            ZenithTabBar(selectedTab: .constant(0))
        }
    }
}
