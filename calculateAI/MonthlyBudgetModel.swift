import Foundation
import SwiftData

@Model
final class MonthlyBudgetModel {
    var categoryID: String
    var month: Int
    var year: Int
    var budgetLimit: Double

    init(categoryID: String, month: Int, year: Int, budgetLimit: Double) {
        self.categoryID = categoryID
        self.month = month
        self.year = year
        self.budgetLimit = budgetLimit
    }
}
