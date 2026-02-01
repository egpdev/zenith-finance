import Foundation
import SwiftData

@Model
final class FinancialGoal {
    var id: UUID
    var title: String
    var currentAmount: Double
    var targetAmount: Double
    var monthlyContribution: Double
    var colorIndex: Int

    init(
        id: UUID = UUID(), title: String, currentAmount: Double, targetAmount: Double,
        monthlyContribution: Double, colorIndex: Int
    ) {
        self.id = id
        self.title = title
        self.currentAmount = currentAmount
        self.targetAmount = targetAmount
        self.monthlyContribution = monthlyContribution
        self.colorIndex = colorIndex
    }

    // Computed properties are not stored, so we can keep helper logic if needed,
    // but SwiftData models usually just hold data.
    // We can use an extension or keep it here if it doesn't conflict.
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
}
