import Foundation
import SwiftData

enum TransactionType: String, CaseIterable, Codable {
    case all = "All"
    case income = "Income"
    case expense = "Expense"
}

enum TransactionCategory: String, CaseIterable, Identifiable, Codable {
    case foodAndDrink = "Food & Drink"
    case transport = "Transport"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case health = "Health"
    case bills = "Bills"
    case salary = "Salary"
    case investment = "Investment"
    case freelance = "Freelance"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .foodAndDrink: return "cup.and.saucer.fill"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "film.fill"
        case .health: return "heart.fill"
        case .bills: return "doc.text.fill"
        case .salary: return "banknote.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .freelance: return "briefcase.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

enum Month: String, CaseIterable, Identifiable, Codable {
    case january = "January"
    case february = "February"
    case march = "March"
    case april = "April"
    case may = "May"
    case june = "June"
    case july = "July"
    case august = "August"
    case september = "September"
    case october = "October"
    case november = "November"
    case december = "December"

    var id: String { rawValue }
}

@Model
final class ZenithTransaction {
    var id: UUID
    var merchant: String
    var date: Date
    var amount: Double
    var type: TransactionType
    var icon: String
    var category: TransactionCategory

    init(
        id: UUID = UUID(), merchant: String, date: Date, amount: Double, type: TransactionType,
        icon: String? = nil, category: TransactionCategory
    ) {
        self.id = id
        self.merchant = merchant
        self.date = date
        self.amount = amount
        self.type = type
        self.category = category
        self.icon = icon ?? category.icon
    }
}
