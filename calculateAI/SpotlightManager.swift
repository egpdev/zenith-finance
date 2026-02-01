import CoreSpotlight
import MobileCoreServices
import SwiftUI

class SpotlightManager {
    static let shared = SpotlightManager()

    private init() {}

    func index(transaction: ZenithTransaction) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = transaction.merchant
        attributeSet.contentDescription =
            "\(transaction.category.rawValue) - $\(Int(transaction.amount))"
        attributeSet.keywords = [
            transaction.category.rawValue, "Zenith", "Transaction", transaction.merchant,
        ]

        // Use a unique ID based on transaction properties since UUID might not be persistent enough if not handled carefully,
        // but here ID is UUID so it works.
        let item = CSSearchableItem(
            uniqueIdentifier: transaction.id.uuidString,
            domainIdentifier: "com.zenith.transactions",
            attributeSet: attributeSet
        )

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("Spotlight indexing error: \(error.localizedDescription)")
            }
        }
    }

    func deindex(transactionId: String) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [transactionId]) {
            error in
            if let error = error {
                print("Spotlight deletion error: \(error.localizedDescription)")
            }
        }
    }
}
