import Foundation
import SwiftData

@Model
final class MonthlyIncomeModel {
    var month: Int
    var year: Int
    var amount: Double

    // Composite ID logic usually handled by checking (month, year) uniqueness
    // But SwiftData doesn't enforce composite unique constraints easily yet without custom validation.
    // We will ensure uniqueness via logic in the View.

    init(month: Int, year: Int, amount: Double) {
        self.month = month
        self.year = year
        self.amount = amount
    }
}
