import Foundation
import SwiftData

@Model
final class CategoryModel {
    var id: String
    var name: String
    var icon: String
    var budgetLimit: Double
    var orderIndex: Int
    var isHidden: Bool

    init(
        id: String, name: String, icon: String, budgetLimit: Double, orderIndex: Int,
        isHidden: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.budgetLimit = budgetLimit
        self.orderIndex = orderIndex
        self.isHidden = isHidden
    }
}
