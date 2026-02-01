//
//  NotificationManager.swift
//  calculateAI
//
//  Push Notifications Manager
//

import Combine
import SwiftUI
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])

            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Schedule Budget Alert
    func scheduleBudgetAlert(category: String, percentUsed: Double, budgetLimit: Double) {
        guard isAuthorized, percentUsed >= 80 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Budget Alert ⚠️"
        content.body =
            "You've used \(Int(percentUsed))% of your \(category) budget ($\(Int(budgetLimit)))"
        content.sound = .default
        content.badge = 1

        // Unique identifier for this category alert
        let identifier =
            "budget-alert-\(category.lowercased().replacingOccurrences(of: " ", with: "-"))"

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule budget alert: \(error)")
            }
        }
    }

    // MARK: - Schedule Weekly Report
    func scheduleWeeklyReport(savings: Double, topCategory: String) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Weekly Report 📊"

        if savings > 0 {
            content.body =
                "Great job! You saved $\(Int(savings)) this week. Top spending: \(topCategory)"
        } else {
            content.body =
                "You overspent by $\(Int(abs(savings))) this week. Top spending: \(topCategory)"
        }
        content.sound = .default

        // Schedule for Sunday at 10 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // Sunday
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "weekly-report",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule weekly report: \(error)")
            }
        }
    }

    // MARK: - Schedule Daily Reminder
    func scheduleDailyReminder(enabled: Bool) {
        let identifier = "daily-reminder"

        if !enabled {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
                identifier
            ])
            return
        }

        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Don't forget! 💰"
        content.body = "Have you logged your expenses today?"
        content.sound = .default

        // Schedule for 8 PM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule daily reminder: \(error)")
            }
        }
    }

    // MARK: - Transaction Alert
    func sendTransactionAlert(merchant: String, amount: Double) {
        guard isAuthorized else { return }
        guard UserDefaults.standard.bool(forKey: "transactionAlertsEnabled") else { return }

        let content = UNMutableNotificationContent()
        content.title = "Transaction Added ✓"
        content.body = "Logged $\(String(format: "%.2f", amount)) at \(merchant)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Clear All Notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        // Use new iOS 17+ API for badge
        Task {
            do {
                try await UNUserNotificationCenter.current().setBadgeCount(0)
            } catch {
                print("Failed to clear badge: \(error)")
            }
        }
    }

    // MARK: - Get Pending Notifications
    func loadPendingNotifications() async {
        pendingNotifications = await UNUserNotificationCenter.current()
            .pendingNotificationRequests()
    }
}

// MARK: - Notification Settings Keys
extension UserDefaults {
    var budgetAlertsEnabled: Bool {
        get { bool(forKey: "budgetAlertsEnabled") }
        set { set(newValue, forKey: "budgetAlertsEnabled") }
    }

    var weeklyReportsEnabled: Bool {
        get { bool(forKey: "weeklyReportsEnabled") }
        set { set(newValue, forKey: "weeklyReportsEnabled") }
    }

    var transactionAlertsEnabled: Bool {
        get { bool(forKey: "transactionAlertsEnabled") }
        set { set(newValue, forKey: "transactionAlertsEnabled") }
    }

    var dailyReminderEnabled: Bool {
        get { bool(forKey: "dailyReminderEnabled") }
        set { set(newValue, forKey: "dailyReminderEnabled") }
    }
}
