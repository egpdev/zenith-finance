//
//  ZenithWidget.swift
//  ZenithWidget
//
//  Zenith Finance Balance Widget
//

import SwiftUI
import WidgetKit

// MARK: - Shared Data Model
struct WidgetData {
    let balance: Double
    let recentTransactions: [WidgetTransaction]
    let monthlySpending: Double
    let monthlyIncome: Double

    static let placeholder = WidgetData(
        balance: 12_450.00,
        recentTransactions: [
            WidgetTransaction(merchant: "Starbucks", amount: -5.75, icon: "cup.and.saucer.fill"),
            WidgetTransaction(merchant: "Amazon", amount: -49.99, icon: "cart.fill"),
            WidgetTransaction(merchant: "Salary", amount: 3500.00, icon: "dollarsign.circle.fill"),
        ],
        monthlySpending: 1_234.56,
        monthlyIncome: 5_000.00
    )

    var formattedBalance: String {
        String(format: "$%.2f", balance)
    }

    var formattedIncome: String {
        String(format: "+$%.0f", monthlyIncome)
    }

    var formattedSpending: String {
        String(format: "-$%.0f", monthlySpending)
    }

    var formattedSaved: String {
        String(format: "$%.0f", monthlyIncome - monthlySpending)
    }
}

struct WidgetTransaction: Identifiable {
    let id = UUID()
    let merchant: String
    let amount: Double
    let icon: String

    var formattedAmount: String {
        if amount >= 0 {
            return String(format: "+$%.0f", amount)
        } else {
            return String(format: "-$%.0f", abs(amount))
        }
    }

    var formattedAmountFull: String {
        if amount >= 0 {
            return String(format: "+$%.2f", amount)
        } else {
            return String(format: "-$%.2f", abs(amount))
        }
    }
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    let suiteName = "group.com.zenith.shared"

    func placeholder(in context: Context) -> BalanceEntry {
        BalanceEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        let entry = BalanceEntry(date: Date(), data: loadData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        let currentDate = Date()
        let entry = BalanceEntry(date: currentDate, data: loadData())

        // Update every 15 minutes or when manually reloaded
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    func loadData() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return .placeholder
        }

        let balance = defaults.double(forKey: "balance")
        let monthlyIncome = defaults.double(forKey: "monthlyIncome")
        let monthlySpending = defaults.double(forKey: "monthlySpending")

        // Retrieve transactions
        var transactions: [WidgetTransaction] = []
        if let savedTransactions = defaults.array(forKey: "recentTransactions") as? [[String: Any]]
        {
            for t in savedTransactions {
                if let merchant = t["merchant"] as? String,
                    let amount = t["amount"] as? Double,
                    let icon = t["icon"] as? String
                {
                    transactions.append(
                        WidgetTransaction(merchant: merchant, amount: amount, icon: icon))
                }
            }
        }

        // If data is completely empty (defaults return 0.0), return placeholder for preview,
        // but for real use we might want zeros. For now, if balance is 0 and no transactions, assume first run.
        if balance == 0 && transactions.isEmpty {
            return .placeholder
        }

        return WidgetData(
            balance: balance,
            recentTransactions: transactions,
            monthlySpending: monthlySpending,
            monthlyIncome: monthlyIncome
        )
    }
}

// MARK: - Timeline Entry
struct BalanceEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: BalanceEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0D0D0D"), Color(hex: "1A1A1A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(Color(hex: "4FFFB0"))
                        .font(.caption)
                    Text("Zenith")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }

                Spacer()

                Text("Balance")
                    .font(.caption2)
                    .foregroundColor(.gray)

                Text(entry.data.formattedBalance)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(
                        systemName: entry.data.monthlyIncome > entry.data.monthlySpending
                            ? "arrow.up.right" : "arrow.down.right"
                    )
                    .font(.system(size: 10))
                    Text(
                        entry.data.monthlyIncome > entry.data.monthlySpending
                            ? "On track" : "Watch spending"
                    )
                    .font(.system(size: 10))
                }
                .foregroundColor(
                    entry.data.monthlyIncome > entry.data.monthlySpending
                        ? Color(hex: "4FFFB0") : .orange
                )
            }
            .padding()
        }
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: BalanceEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0D0D0D"), Color(hex: "1A1A1A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(Color(hex: "4FFFB0"))
                        Text("Zenith")
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .font(.caption)

                    Spacer()

                    Text("Balance")
                        .font(.caption2)
                        .foregroundColor(.gray)

                    Text(entry.data.formattedBalance)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text("Income")
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                            Text(entry.data.formattedIncome)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }
                        VStack(alignment: .leading) {
                            Text("Spent")
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                            Text(entry.data.formattedSpending)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red)
                        }
                    }
                }

                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent")
                        .font(.caption2)
                        .foregroundColor(.gray)

                    ForEach(entry.data.recentTransactions.prefix(3)) { transaction in
                        HStack {
                            Image(systemName: transaction.icon)
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "4FFFB0"))
                                .frame(width: 16)

                            Text(transaction.merchant)
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Spacer()

                            Text(transaction.formattedAmount)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(transaction.amount >= 0 ? .green : .white)
                        }
                    }

                    Spacer()
                }
            }
            .padding()
        }
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: BalanceEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0D0D0D"), Color(hex: "1A1A1A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                HStack {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(Color(hex: "4FFFB0"))
                        Text("Zenith Finance")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text(entry.date, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Balance")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(entry.data.formattedBalance)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "4FFFB0").opacity(0.1))
                            .frame(width: 60, height: 40)
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundColor(Color(hex: "4FFFB0"))
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                HStack(spacing: 12) {
                    StatBox(
                        title: "Income",
                        value: entry.data.formattedIncome,
                        color: .green
                    )
                    StatBox(
                        title: "Spending",
                        value: entry.data.formattedSpending,
                        color: .red
                    )
                    StatBox(
                        title: "Saved",
                        value: entry.data.formattedSaved,
                        color: Color(hex: "4FFFB0")
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Transactions")
                        .font(.caption)
                        .foregroundColor(.gray)

                    ForEach(entry.data.recentTransactions) { transaction in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "4FFFB0").opacity(0.15))
                                    .frame(width: 28, height: 28)
                                Image(systemName: transaction.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "4FFFB0"))
                            }

                            Text(transaction.merchant)
                                .font(.subheadline)
                                .foregroundColor(.white)

                            Spacer()

                            Text(transaction.formattedAmountFull)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(transaction.amount >= 0 ? .green : .white)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Widget Configuration
struct ZenithBalanceWidget: Widget {
    let kind: String = "ZenithWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ZenithWidgetEntryView(entry: entry)
                .containerBackground(Color(hex: "0D0D0D"), for: .widget)  // FIXED: Replaced .fill.tertiary with Dark Hex Color
        }
        .configurationDisplayName("Zenith Balance")
        .description("Track your balance and recent transactions.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()  // Apply this to remove default margins if needed
    }
}

struct ZenithWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: BalanceEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview("Small", as: .systemSmall) {
    ZenithBalanceWidget()
} timeline: {
    BalanceEntry(date: .now, data: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    ZenithBalanceWidget()
} timeline: {
    BalanceEntry(date: .now, data: .placeholder)
}

#Preview("Large", as: .systemLarge) {
    ZenithBalanceWidget()
} timeline: {
    BalanceEntry(date: .now, data: .placeholder)
}
