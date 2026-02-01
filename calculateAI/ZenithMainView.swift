import SwiftData
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

struct ZenithMainView: View {

    // No init needed for TabBar appearance anymore

    @State private var selection = 0

    // Shared Persistence
    @Query(sort: \ZenithTransaction.date, order: .reverse) private var transactions:
        [ZenithTransaction]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selection {
                case 0:
                    ZenithDashboardView(
                        transactions: transactions,
                        onNavigateToTransactions: { selection = 1 }
                    )
                case 1:
                    ZenithTransactionsView(selectedTab: $selection, transactions: transactions)
                case 2:
                    ZenithPlannerView(transactions: transactions)
                case 3:
                    ZenithProfileView()
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating Tab Bar
            ZenithTabBar(selectedTab: $selection)
                .padding(.bottom, 0)  // Already padded inside component
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // Initial sync on app launch
            syncToWidget(transactions: transactions)
        }
        .onChange(of: transactions) { _, newTransactions in
            syncToWidget(transactions: newTransactions)
        }
    }

    private func syncToWidget(transactions: [ZenithTransaction]) {
        let balance = transactions.reduce(0) { $0 + ($1.type == .income ? $1.amount : -$1.amount) }

        // Simple Monthly Filter
        let calendar = Calendar.current
        let now = Date()
        let currentMonthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }

        let income =
            currentMonthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }

        let spending =
            currentMonthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }

        WidgetDataManager.shared.save(
            balance: balance,
            income: income,
            spending: spending
        )

        WidgetDataManager.shared.saveRecentTransactions(transactions)
    }
}

#Preview {
    ZenithMainView()
}
