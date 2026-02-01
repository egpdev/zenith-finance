import SwiftUI

struct ZenithLockScreen: View {
    @ObservedObject var securityManager = SecurityManager.shared

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.mintGreen)

                Text("Zenith Locked")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Button(action: {
                    securityManager.authenticate()
                }) {
                    Text("Unlock with Face ID")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .padding(.horizontal, 20)
                        .background(Color.mintGreen)
                        .cornerRadius(30)
                }
            }
        }
        .onAppear {
            securityManager.authenticate()
        }
    }
}
