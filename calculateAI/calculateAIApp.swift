//
//  calculateAIApp.swift
//  calculateAI
//
//  Created by Minamino Shuichi on 20.01.26.
//

import Combine
import SwiftData
import SwiftUI

@main
struct calculateAIApp: App {
    @State private var modelContainerError: String? = nil

    var sharedModelContainer: ModelContainer? = {
        let schema = Schema([
            ZenithTransaction.self,
            CategoryModel.self,
            MonthlyBudgetModel.self,
            MonthlyIncomeModel.self,
            FinancialGoal.self,
            RecurringTransaction.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Critical: Could not create ModelContainer: \(error)")
            return nil
        }
    }()

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var securityManager = SecurityManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if let container = sharedModelContainer {
                ZStack {
                    if securityManager.isLocked {
                        ZenithLockScreen()
                    } else {
                        if hasSeenOnboarding {
                            ZenithMainView()
                                .onAppear { seedCategories(context: container.mainContext) }
                        } else {
                            ZenithOnboardingView()
                                .onAppear { seedCategories(context: container.mainContext) }
                        }
                    }
                }
                .animation(.easeInOut, value: securityManager.isLocked)
                .modelContainer(container)
            } else {
                // Error State UI
                DatabaseErrorView()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                // Lock when leaving app
                securityManager.lock()
            } else if newPhase == .inactive {
                // Also lock on inactive to blur in app switcher
                if securityManager.biometricsEnabled {
                    securityManager.lock()
                }
            }
        }
    }

    @MainActor
    private func seedCategories(context: ModelContext) {
        let descriptor = FetchDescriptor<CategoryModel>()
        do {
            let count = try context.fetchCount(descriptor)
            if count == 0 {
                print("Spending AI: Seeding default categories...")
                for (index, category) in TransactionCategory.allCases.enumerated() {
                    let model = CategoryModel(
                        id: category.rawValue,
                        name: category.rawValue,
                        icon: category.icon,
                        budgetLimit: defaultBudget(for: category),
                        orderIndex: index
                    )
                    context.insert(model)
                }
            }
        } catch {
            print("Failed to fetch/seed categories: \(error)")
        }
    }

    private func defaultBudget(for category: TransactionCategory) -> Double {
        // Match the previous hardcoded defaults
        switch category {
        case .foodAndDrink: return 600
        case .transport: return 300
        case .bills: return 1200
        case .entertainment: return 200
        case .shopping: return 400
        case .health: return 150
        case .other: return 200
        case .salary, .investment, .freelance: return 0  // Income categories don't usually have spending limits
        }
    }
}

// MARK: - Database Error View
struct DatabaseErrorView: View {
    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)

                Text("Database Error")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(
                    "Could not initialize the app database.\nPlease try reinstalling the app or contact support."
                )
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.top, 100)
        }
    }
}
