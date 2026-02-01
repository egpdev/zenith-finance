//
//  WidgetDataManager.swift
//  calculateAI
//
//  Created for Zenith Finance
//

import Foundation
import WidgetKit

struct WidgetDataManager {
    static let shared = WidgetDataManager()
    let suiteName = "group.com.zenith.shared"

    func save(balance: Double, income: Double, spending: Double) {
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.set(balance, forKey: "balance")
        defaults?.set(income, forKey: "monthlyIncome")
        defaults?.set(spending, forKey: "monthlySpending")
        defaults?.set(Date(), forKey: "lastUpdated")

        // Reload widget timeline
        WidgetCenter.shared.reloadAllTimelines()

        print("Creating app group data: Balance \(balance)")
    }

    func saveRecentTransactions(_ transactions: [ZenithTransaction]) {
        let defaults = UserDefaults(suiteName: suiteName)

        // Map to light structure for widget
        let widgetTransactions = transactions.prefix(3).map { transaction in
            [
                "merchant": transaction.merchant,
                "amount": transaction.amount,
                "icon": transaction.category.icon,
            ] as [String: Any]
        }

        defaults?.set(widgetTransactions, forKey: "recentTransactions")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
