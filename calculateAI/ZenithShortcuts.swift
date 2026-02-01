import AppIntents
import SwiftData
import SwiftUI

// MARK: - App Shortcut Provider
struct ZenithShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTransactionIntent(),
            phrases: [
                "Add transaction to \(.applicationName)",
                "New expense in \(.applicationName)",
                "Log spending in \(.applicationName)",
            ],
            shortTitle: "Add Transaction",
            systemImageName: "plus.circle.fill"
        )
    }
}

// MARK: - Add Transaction Intent
struct AddTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Transaction"
    static var description = IntentDescription("Quickly add a new transaction to Zenith.")
    static var openAppWhenRun: Bool = true  // Open app to finish details for now (simpler MVP)

    @MainActor
    func perform() async throws -> some IntentResult {
        // Deep link logic would go here, or just opening the app context
        // For now, we launch the app which will handle the intent via a state flag if needed
        return .result(dialog: "Opening Zenith to add your transaction.")
    }
}
