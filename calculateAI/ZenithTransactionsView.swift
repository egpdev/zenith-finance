import SwiftData
import SwiftUI

// MARK: - Models
// Models are now defined in TransactionModel.swift

// MARK: - Main View

struct ZenithTransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: Int

    // START: State Properties
    @State private var showingScanner = false
    @State private var showingVoiceInput = false
    @State private var showingDetail = false
    @State private var showingAddTransaction = false
    @State private var selectedTransaction: ZenithTransaction?

    // Search & Filter
    @State private var searchText = ""
    @State private var selectedFilter: TransactionType = .all
    @State private var showSearch = false

    let transactions: [ZenithTransaction]

    // Computed Properties
    var filteredTransactions: [ZenithTransaction] {
        transactions.filter { transaction in
            let matchesFilter = selectedFilter == .all || transaction.type == selectedFilter
            let matchesSearch =
                searchText.isEmpty
                || transaction.merchant.localizedCaseInsensitiveContains(searchText)
                || transaction.category.rawValue.localizedCaseInsensitiveContains(searchText)
            return matchesFilter && matchesSearch
        }
        .sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        ZStack {
            ZenithBackground()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 20) {
                    // Top Bar
                    ZStack {
                        // Centered Title
                        Text("Transactions")
                            .font(.headline)
                            .foregroundColor(.white)
                            .opacity(0.8)

                        // Leading/Trailing Buttons
                        HStack {
                            Button(action: {
                                selectedTab = 0  // Switch to Dashboard
                            }) {
                                Image(systemName: "house.fill")
                                    .foregroundColor(Color.mintGreen)
                                    .padding(10)
                                    .background(Color.mintGreen.opacity(0.1) as Color)
                                    .clipShape(Circle())
                            }

                            Spacer()

                            // Add Button
                            Button(action: {
                                showingAddTransaction = true
                            }) {
                                Image(systemName: "plus")
                                    .foregroundColor(.black)
                                    .padding(10)
                                    .background(Color.mintGreen)
                                    .clipShape(Circle())
                            }

                            Button(action: {
                                withAnimation { showSearch.toggle() }
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color(white: 1.0, opacity: 0.05))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    HStack {
                        Text("Recent Activity")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color.neonTurquoise.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Spacer()

                        Menu {
                            ForEach(TransactionType.allCases, id: \.self) { type in
                                Button(action: { selectedFilter = type }) {
                                    HStack {
                                        Text(type.rawValue)
                                        if selectedFilter == type {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedFilter.rawValue)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                            }
                            .font(.subheadline)
                            .foregroundColor(.mintGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.mintGreen.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)

                    // Search Bar (Collapsible)
                    if showSearch {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search transactions...", text: $searchText)
                                .foregroundColor(.white)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.bottom)

                // MARK: - ZenithTransaction List
                List {
                    ForEach(filteredTransactions) { transaction in
                        Button(action: {
                            selectedTransaction = transaction
                            showingDetail = true
                        }) {
                            TransactionRow(transaction: transaction)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    // Swipe to Delete
                    .onDelete { indexSet in
                        let transactionsToDelete = indexSet.map { filteredTransactions[$0] }
                        for transaction in transactionsToDelete {
                            SpotlightManager.shared.deindex(
                                transactionId: transaction.id.uuidString)
                            modelContext.delete(transaction)
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.clear)
                .scrollContentBackground(.hidden)
            }

            // MARK: - Bottom Action Bar (Removed to avoid conflict with Tab Bar)
            // The Scan and Voice features are accessible via Dashboard Quick Actions.

            // Interaction Modals
            if showingVoiceInput {
                ZenithVoiceInputView(isPresented: $showingVoiceInput)
                    .zIndex(2)
            }
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(transaction: transaction)
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
    }
}

// MARK: - Components

struct BaseTransactionRow: View {
    // A non-button version of the row design to avoid gesture conflicts if needed
    let transaction: ZenithTransaction

    // ... implementation similar to TransactionRow but without built-in interactions
    // For this task, we will reuse TransactionRow but ensure it works with List/ForEach
    var body: some View {
        TransactionRow(transaction: transaction)
    }
}

struct TransactionRow: View {
    let transaction: ZenithTransaction

    // Formatting Helpers
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: transaction.date)
    }

    private var formattedAmount: String {
        let sign = transaction.type == .income ? "+" : "-"
        return "\(sign)$\(String(format: "%.2f", abs(transaction.amount)))"
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: transaction.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 1.0, opacity: 0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(formattedAmount)
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(transaction.type == .income ? .white : .gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .opacity(0.6)
                .shadow(color: Color.black.opacity(0.2) as Color, radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .contentShape(Rectangle())  // Make the whole area tappable/swipable
    }
}

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode
    @Query(sort: \CategoryModel.orderIndex) private var userCategories: [CategoryModel]

    @State private var merchant = ""
    @State private var amountString = ""
    @State private var type: TransactionType = .expense
    @State private var category: TransactionCategory = .other
    @State private var selectedUserCategoryID: String? = nil
    @State private var useCustomCategory = false

    var body: some View {
        ZStack {
            ZenithBackground()

            VStack(spacing: 24) {
                Text("New Transaction")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.neonTurquoise],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.top)

                VStack(spacing: 16) {
                    // Merchant (only show if no category selected OR type is income)
                    if !useCustomCategory || type == .income {
                        TextField("Merchant (e.g. Starbucks)", text: $merchant)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    } else {
                        // Show selected category name
                        HStack {
                            if let selectedCat = userCategories.first(where: {
                                $0.id == selectedUserCategoryID
                            }) {
                                Image(systemName: selectedCat.icon)
                                    .foregroundColor(.mintGreen)
                                Text(selectedCat.name)
                                    .foregroundColor(.white)
                                    .fontWeight(.medium)
                                Spacer()
                                Button(action: {
                                    useCustomCategory = false
                                    selectedUserCategoryID = nil
                                    merchant = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color.mintGreen.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Amount
                    TextField("Amount (e.g. 15.50)", text: $amountString)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    // Type Picker
                    Picker("Type", selection: $type) {
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .colorMultiply(.mintGreen)
                    .onChange(of: type) { _, newValue in
                        // Clear selected category when switching to Income
                        if newValue == .income {
                            useCustomCategory = false
                            selectedUserCategoryID = nil
                        }
                    }

                    // Category Section (only for Expense)
                    if type == .expense {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SELECT CATEGORY")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)

                            // Quick select from user categories
                            if !userCategories.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(userCategories.filter { !$0.isHidden }) { cat in
                                            Button(action: {
                                                selectedUserCategoryID = cat.id
                                                useCustomCategory = true
                                                merchant = cat.name  // Auto-fill merchant
                                                category =
                                                    TransactionCategory(rawValue: cat.id) ?? .other
                                            }) {
                                                VStack(spacing: 6) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(
                                                                selectedUserCategoryID == cat.id
                                                                    ? Color.mintGreen
                                                                    : Color.white.opacity(0.1)
                                                            )
                                                            .frame(width: 50, height: 50)
                                                        Image(systemName: cat.icon)
                                                            .font(.title3)
                                                            .foregroundColor(
                                                                selectedUserCategoryID == cat.id
                                                                    ? .black : .white)
                                                    }
                                                    Text(cat.name)
                                                        .font(.caption2)
                                                        .foregroundColor(
                                                            selectedUserCategoryID == cat.id
                                                                ? .mintGreen : .gray
                                                        )
                                                        .lineLimit(1)
                                                }
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            } else {
                                // Only show built-in if no user categories
                                HStack {
                                    Text("Category:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Picker("Category", selection: $category) {
                                        ForEach(TransactionCategory.allCases) { cat in
                                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                                        }
                                    }
                                    .tint(.mintGreen)
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()

                Spacer()

                Button(action: saveTransaction) {
                    Text("Save Transaction")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mintGreen)
                        .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    private func saveTransaction() {
        guard let amount = Double(amountString), !merchant.isEmpty else { return }

        // Use selectedUserCategoryID if available, otherwise use the enum
        let finalCategory: TransactionCategory
        if let customID = selectedUserCategoryID, useCustomCategory {
            finalCategory = TransactionCategory(rawValue: customID) ?? .other
        } else {
            finalCategory = category
        }

        let newTransaction = ZenithTransaction(
            merchant: merchant,
            date: Date(),
            amount: type == .income ? abs(amount) : -abs(amount),
            type: type,
            category: finalCategory
        )

        modelContext.insert(newTransaction)
        SpotlightManager.shared.index(transaction: newTransaction)
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditTransactionView: View {
    @Bindable var transaction: ZenithTransaction
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode

    @State private var merchant: String
    @State private var amountString: String
    @State private var type: TransactionType
    @State private var category: TransactionCategory

    init(transaction: ZenithTransaction) {
        self.transaction = transaction
        _merchant = State(initialValue: transaction.merchant)
        _amountString = State(initialValue: String(format: "%.2f", abs(transaction.amount)))
        _type = State(initialValue: transaction.type)
        _category = State(initialValue: transaction.category)
    }

    var body: some View {
        ZStack {
            ZenithBackground()

            VStack(spacing: 24) {
                Text("Edit ZenithTransaction")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)

                VStack(spacing: 16) {
                    TextField("Merchant", text: $merchant)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)

                    TextField("Amount", text: $amountString)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)

                    Picker("Type", selection: $type) {
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .colorMultiply(.mintGreen)

                    HStack {
                        Text("Category")
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("Category", selection: $category) {
                            ForEach(TransactionCategory.allCases) { cat in
                                Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                            }
                        }
                        .tint(.mintGreen)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .cornerRadius(12)
                }
                .padding()

                Spacer()

                VStack(spacing: 16) {
                    Button(action: saveChanges) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.mintGreen)
                            .cornerRadius(16)
                    }

                    Button(action: deleteTransaction) {
                        Text("Delete ZenithTransaction")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    private func saveChanges() {
        guard let amount = Double(amountString), !merchant.isEmpty else { return }

        // Update the object directly. SwiftData tracks changes.
        transaction.merchant = merchant
        transaction.amount = type == .income ? abs(amount) : -abs(amount)
        transaction.type = type
        transaction.category = category
        transaction.icon = category.icon

        // Explicitly saving context is not strictly required if autosave is on, but good practice.
        // try? modelContext.save()

        presentationMode.wrappedValue.dismiss()
    }

    private func deleteTransaction() {
        SpotlightManager.shared.deindex(transactionId: transaction.id.uuidString)
        modelContext.delete(transaction)
        presentationMode.wrappedValue.dismiss()
    }
}

struct TransactionDetailView: View {
    let transaction: ZenithTransaction
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEdit = false

    // Initializer unused explicitly if memberwise is fine, but let's keep it simple
    init(transaction: ZenithTransaction) {
        self.transaction = transaction
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: transaction.date)
    }

    private var formattedAmount: String {
        let sign = transaction.type == .income ? "+" : "-"
        return "\(sign)$\(String(format: "%.2f", abs(transaction.amount)))"
    }

    var body: some View {
        ZStack {
            ZenithBackground()

            VStack(spacing: 24) {
                // Handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top)

                // Top Actions
                HStack {
                    Spacer()
                    Button("Edit") {
                        showingEdit = true
                    }
                    .foregroundColor(.mintGreen)
                    .padding(.trailing)
                }

                // Icon
                Image(systemName: transaction.icon)
                    .font(.system(size: 40))
                    .foregroundColor(Color.mintGreen)
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(Color.mintGreen.opacity(0.1))
                            .overlay(Circle().stroke(Color.mintGreen.opacity(0.3), lineWidth: 1))
                    )

                // Amount & Title
                VStack(spacing: 8) {
                    Text(formattedAmount)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(transaction.type == .income ? .white : .white)

                    Text(transaction.merchant)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                }

                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal)

                // Details Grid
                VStack(spacing: 20) {
                    DetailRow(label: "Date", value: formattedDate)
                    DetailRow(label: "Category", value: transaction.category.rawValue)
                    DetailRow(label: "Status", value: "Completed")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)

                Spacer()

                // Close Button
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditTransactionView(transaction: transaction)
                .onDisappear {
                    // Refresh logic handled by SwiftData observation usually
                    if transaction.isDeleted {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ZenithTransactionsView(
        selectedTab: .constant(1),
        transactions: [
            ZenithTransaction(
                merchant: "Preview Coffee", date: Date(), amount: 5.50, type: .expense,
                category: .foodAndDrink)
        ])
}
