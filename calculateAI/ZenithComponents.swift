import SwiftUI

struct ZenithBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            // Northern Lights (Aurora) Effect
            GeometryReader { proxy in
                ZStack {
                    // Greenish glow top right
                    Ellipse()
                        .fill(Color.mintGreen.opacity(0.2))
                        .frame(width: proxy.size.width * 1.2, height: proxy.size.height * 0.5)
                        .offset(x: animate ? 50 : 0, y: animate ? -50 : -100)
                        .blur(radius: 80)
                        .rotationEffect(.degrees(-30))

                    // Turquoise glow top left
                    Ellipse()
                        .fill(Color.neonTurquoise.opacity(0.15))
                        .frame(width: proxy.size.width * 1.5, height: proxy.size.height * 0.4)
                        .offset(x: animate ? -50 : -200, y: animate ? 0 : -50)
                        .blur(radius: 90)
                        .rotationEffect(.degrees(-10))

                    // Subtle Purple/Blue deep glow for depth
                    Ellipse()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: proxy.size.width * 1.5, height: proxy.size.height * 0.6)
                        .offset(x: 0, y: animate ? 100 : 200)
                        .blur(radius: 100)
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}
