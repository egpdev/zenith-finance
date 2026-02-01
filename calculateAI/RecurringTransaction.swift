//
//  RecurringTransaction.swift
//  calculateAI
//
//  Recurring Transaction Model and Manager
//

import Combine
import Foundation
import SwiftData
import SwiftUI

// MARK: - Frequency Enum
enum RecurringFrequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"

    var icon: String {
        switch self {
        case .daily: return "arrow.clockwise"
        case .weekly: return "calendar.badge.clock"
        case .biweekly: return "calendar"
        case .monthly: return "calendar.circle"
        case .quarterly: return "chart.bar"
        case .yearly: return "calendar.badge.exclamationmark"
        }
    }

    var days: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .yearly: return 365
        }
    }
}

// MARK: - Recurring Transaction Model
@Model
final class RecurringTransaction {
    var id: UUID
    var merchant: String
    var amount: Double
    var type: TransactionType
    var category: TransactionCategory
    var frequency: RecurringFrequency
    var startDate: Date
    var nextDueDate: Date
    var lastGeneratedDate: Date?
    var isActive: Bool
    var notifyBeforeDays: Int  // 0 = don't notify

    init(
        id: UUID = UUID(),
        merchant: String,
        amount: Double,
        type: TransactionType,
        category: TransactionCategory,
        frequency: RecurringFrequency,
        startDate: Date = Date(),
        notifyBeforeDays: Int = 1
    ) {
        self.id = id
        self.merchant = merchant
        self.amount = amount
        self.type = type
        self.category = category
        self.frequency = frequency
        self.startDate = startDate
        self.nextDueDate = startDate
        self.lastGeneratedDate = nil
        self.isActive = true
        self.notifyBeforeDays = notifyBeforeDays
    }

    func calculateNextDueDate() {
        let calendar = Calendar.current

        switch frequency {
        case .daily:
            nextDueDate = calendar.date(byAdding: .day, value: 1, to: nextDueDate) ?? nextDueDate
        case .weekly:
            nextDueDate =
                calendar.date(byAdding: .weekOfYear, value: 1, to: nextDueDate)
                ?? nextDueDate
        case .biweekly:
            nextDueDate =
                calendar.date(byAdding: .weekOfYear, value: 2, to: nextDueDate)
                ?? nextDueDate
        case .monthly:
            nextDueDate = calendar.date(byAdding: .month, value: 1, to: nextDueDate) ?? nextDueDate
        case .quarterly:
            nextDueDate = calendar.date(byAdding: .month, value: 3, to: nextDueDate) ?? nextDueDate
        case .yearly:
            nextDueDate = calendar.date(byAdding: .year, value: 1, to: nextDueDate) ?? nextDueDate
        }
    }
}

// MARK: - Recurring Transaction Manager
@MainActor
class RecurringTransactionManager: ObservableObject {
    static let shared = RecurringTransactionManager()

    @Published var upcomingTransactions: [RecurringTransaction] = []

    private init() {}

    /// Check and generate due recurring transactions
    func processDueTransactions(context: ModelContext) {
        let descriptor = FetchDescriptor<RecurringTransaction>(
            predicate: #Predicate { $0.isActive == true }
        )

        do {
            let recurringTransactions = try context.fetch(descriptor)
            let today = Date()

            for recurring in recurringTransactions {
                // Check if due date has passed
                if recurring.nextDueDate <= today {
                    // Generate the transaction
                    let newTransaction = ZenithTransaction(
                        merchant: recurring.merchant,
                        date: recurring.nextDueDate,
                        amount: recurring.amount,
                        type: recurring.type,
                        category: recurring.category
                    )
                    context.insert(newTransaction)

                    // Update recurring transaction
                    recurring.lastGeneratedDate = recurring.nextDueDate
                    recurring.calculateNextDueDate()

                    // Index in Spotlight
                    SpotlightManager.shared.index(transaction: newTransaction)

                    print(
                        "Generated recurring transaction: \(recurring.merchant) - $\(recurring.amount)"
                    )
                }

                // Schedule notification if needed
                if recurring.notifyBeforeDays > 0 {
                    scheduleNotification(for: recurring)
                }
            }

            // Update upcoming list
            updateUpcomingTransactions(from: recurringTransactions)

        } catch {
            print("Error processing recurring transactions: \(error)")
        }
    }

    private func updateUpcomingTransactions(from transactions: [RecurringTransaction]) {
        let calendar = Calendar.current
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        upcomingTransactions =
            transactions
            .filter { $0.nextDueDate <= nextWeek }
            .sorted { $0.nextDueDate < $1.nextDueDate }
    }

    private func scheduleNotification(for recurring: RecurringTransaction) {
        guard recurring.notifyBeforeDays > 0 else { return }

        let notifyDate = Calendar.current.date(
            byAdding: .day,
            value: -recurring.notifyBeforeDays,
            to: recurring.nextDueDate
        )

        guard let notifyDate = notifyDate, notifyDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Payment 📅"
        content.body =
            "\(recurring.merchant) ($\(String(format: "%.2f", recurring.amount))) is due \(recurring.notifyBeforeDays == 1 ? "tomorrow" : "in \(recurring.notifyBeforeDays) days")"
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour], from: notifyDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "recurring-\(recurring.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Add Recurring Transaction View
struct AddRecurringTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext

    @State private var merchant = ""
    @State private var amount = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategory: TransactionCategory = .bills
    @State private var selectedFrequency: RecurringFrequency = .monthly
    @State private var startDate = Date()
    @State private var notifyBefore = true

    var body: some View {
        NavigationView {
            ZStack {
                Color.zenithBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Merchant
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Merchant / Description")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("e.g. Netflix, Rent, Gym", text: $merchant)
                                .textFieldStyle(ZenithTextFieldStyle())
                        }

                        // Amount
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount")
                                .font(.caption)
                                .foregroundColor(.gray)
                            HStack {
                                Text("$")
                                    .foregroundColor(.mintGreen)
                                    .font(.title2)
                                TextField("0.00", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }

                        // Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Picker("Type", selection: $selectedType) {
                                Text("Expense").tag(TransactionType.expense)
                                Text("Income").tag(TransactionType.income)
                            }
                            .pickerStyle(.segmented)
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.caption)
                                .foregroundColor(.gray)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                                        Button(action: { selectedCategory = category }) {
                                            VStack(spacing: 4) {
                                                Image(systemName: category.icon)
                                                    .font(.title3)
                                                Text(category.rawValue)
                                                    .font(.caption2)
                                            }
                                            .foregroundColor(
                                                selectedCategory == category ? .black : .white
                                            )
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedCategory == category
                                                    ? Color.mintGreen : Color.white.opacity(0.1)
                                            )
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }

                        // Frequency
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Frequency")
                                .font(.caption)
                                .foregroundColor(.gray)
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()), GridItem(.flexible()),
                                    GridItem(.flexible()),
                                ], spacing: 12
                            ) {
                                ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                                    Button(action: { selectedFrequency = freq }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: freq.icon)
                                            Text(freq.rawValue)
                                                .font(.caption)
                                        }
                                        .foregroundColor(
                                            selectedFrequency == freq ? .black : .white
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            selectedFrequency == freq
                                                ? Color.mintGreen : Color.white.opacity(0.1)
                                        )
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }

                        // Start Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start Date")
                                .font(.caption)
                                .foregroundColor(.gray)
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .accentColor(.mintGreen)
                        }

                        // Notification Toggle
                        Toggle(isOn: $notifyBefore) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.mintGreen)
                                Text("Notify 1 day before")
                                    .foregroundColor(.white)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .mintGreen))

                        // Save Button
                        Button(action: saveRecurring) {
                            Text("Create Recurring Transaction")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.mintGreen)
                                .cornerRadius(16)
                        }
                        .disabled(merchant.isEmpty || amount.isEmpty)
                        .opacity(merchant.isEmpty || amount.isEmpty ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("Recurring Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.mintGreen)
                }
            }
        }
    }

    private func saveRecurring() {
        guard let amountValue = Double(amount) else { return }

        let recurring = RecurringTransaction(
            merchant: merchant,
            amount: amountValue,
            type: selectedType,
            category: selectedCategory,
            frequency: selectedFrequency,
            startDate: startDate,
            notifyBeforeDays: notifyBefore ? 1 : 0
        )

        modelContext.insert(recurring)
        HapticManager.shared.success()
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Recurring Transactions List View
struct RecurringTransactionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringTransaction.nextDueDate) private var recurringTransactions:
        [RecurringTransaction]

    @State private var showingAddSheet = false

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Recurring")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.mintGreen)
                    }
                }
                .padding()

                if recurringTransactions.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No Recurring Transactions")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Add subscriptions, bills, and regular payments")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(recurringTransactions) { recurring in
                            RecurringTransactionRow(recurring: recurring)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteRecurring)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRecurringTransactionView()
        }
    }

    private func deleteRecurring(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(recurringTransactions[index])
        }
    }
}

// MARK: - Recurring Transaction Row
struct RecurringTransactionRow: View {
    let recurring: RecurringTransaction

    private var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: recurring.nextDueDate).day ?? 0
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: recurring.category.icon)
                    .foregroundColor(categoryColor)
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(recurring.merchant)
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Label(recurring.frequency.rawValue, systemImage: recurring.frequency.icon)
                        .font(.caption)
                        .foregroundColor(.gray)

                    if daysUntilDue <= 3 && daysUntilDue >= 0 {
                        Text(daysUntilDue == 0 ? "Today" : "In \(daysUntilDue)d")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            // Amount
            Text(
                recurring.type == .expense
                    ? "-$\(String(format: "%.2f", recurring.amount))"
                    : "+$\(String(format: "%.2f", recurring.amount))"
            )
            .font(.headline)
            .foregroundColor(recurring.type == .expense ? .white : .green)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    private var categoryColor: Color {
        switch recurring.category {
        case .foodAndDrink: return .orange
        case .transport: return .blue
        case .shopping: return .purple
        case .entertainment: return .pink
        case .health: return .red
        case .bills: return .yellow
        case .salary, .investment, .freelance: return .green
        case .other: return .gray
        }
    }
}

// MARK: - Zenith Text Field Style
struct ZenithTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .foregroundColor(.white)
    }
}
