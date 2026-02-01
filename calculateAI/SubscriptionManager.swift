//
//  SubscriptionManager.swift
//  calculateAI
//
//  In-App Purchase Manager with StoreKit 2
//

import Combine
import StoreKit
import SwiftUI

// Type alias to avoid conflict with SwiftData Transaction
typealias StoreTransaction = StoreKit.Transaction

// MARK: - Subscription Manager
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var isLoading = false

    enum SubscriptionStatus: Equatable {
        case notSubscribed
        case subscribed(expirationDate: Date?)
        case expired
    }

    // Product IDs - configure these in App Store Connect
    private let productIds = [
        "com.zenith.premium.monthly",
        "com.zenith.premium.yearly",
    ]

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIds)
            products.sort { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> StoreTransaction? {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }

    // MARK: - Check Subscription Status
    func updateSubscriptionStatus() async {
        var foundSubscription = false

        for await result in StoreTransaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .autoRenewable {
                    foundSubscription = true
                    subscriptionStatus = .subscribed(expirationDate: transaction.expirationDate)
                }
            }
        }

        if !foundSubscription {
            subscriptionStatus = .notSubscribed
        }
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreTransaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    var isPremium: Bool {
        if case .subscribed = subscriptionStatus {
            return true
        }
        return false
    }
}

enum StoreError: Error {
    case failedVerification
}

// MARK: - Premium Feature Check Extension
extension SubscriptionManager {
    func requirePremium(for feature: String) -> Bool {
        if isPremium { return true }
        // Could show upgrade prompt here
        return false
    }
}
