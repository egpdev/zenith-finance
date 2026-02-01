import Combine
import Foundation
import LocalAuthentication
import SwiftUI

class SecurityManager: ObservableObject {
    static let shared = SecurityManager()
    @Published var isLocked = true

    // Check if user has enabled biometric lock in settings
    // Check if user has enabled biometric lock in settings
    var biometricsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "biometricsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "biometricsEnabled") }
    }

    private init() {}

    func authenticate() {
        // If disabled, unlock immediately
        guard biometricsEnabled else {
            isLocked = false
            return
        }

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock Zenith Financial"

            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics, localizedReason: reason
            ) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isLocked = false
                    } else {
                        // Keep locked or handle retry
                        print("Authentication failed")
                    }
                }
            }
        } else {
            // No biometrics available, fall back or unlock
            isLocked = false
        }
    }

    func lock() {
        if biometricsEnabled {
            isLocked = true
        }
    }
}
