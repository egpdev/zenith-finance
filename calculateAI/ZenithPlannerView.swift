import SwiftData
import SwiftUI

struct ZenithPlannerView: View {
    let transactions: [ZenithTransaction]

    // Persistent Categories
    @Query(sort: \CategoryModel.orderIndex) private var categories: [CategoryModel]
    @Query private var monthlyBudgets: [MonthlyBudgetModel]
    @Query private var monthlyIncomes: [MonthlyIncomeModel]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedMonth: Month = {
        let monthInt = Calendar.current.component(.month, from: Date())
        // Month enum is likely 1-indexed conceptually or we map it.
        // Checking the Month enum order: january, february...
        // So rawValue "January", "February". CaseIterable order usually matches definition order.
        let months = Month.allCases
        return months.count >= monthInt ? months[monthInt - 1] : .january
    }()
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var incomeString: String = "5000"
    @State private var aiAdvice: String = "Analyzing your spending patterns..."
    @State private var isAnalyzing = false

    // Edit Mode State
    // Add Category State
    @State private var showingAddCategorySheet = false
    @State private var editingCategoryModel: CategoryModel?

    @State private var budgetEditValue: String = ""
    @State private var nameEditValue: String = ""

    // Income Edit
    @State private var showingIncomeAlert = false
    @State private var tempIncomeString = ""

    @State private var showingIconPicker = false
    @State private var categoryToCustomize: CategoryModel?

    // MARK: - Computed Properties

    private var displayCategories: [CategoryModel] {
        categories.filter { !$0.isHidden }
    }

    // Helper to match transaction category enum to our custom model ID
    private func model(for transactionCategory: TransactionCategory) -> CategoryModel? {
        categories.first(where: { $0.id == transactionCategory.rawValue })
    }

    private var currentMonthTransactions: [ZenithTransaction] {
        let calendar = Calendar.current

        // Match transactions to selectedMonth and selectedYear
        let monthIndex = Month.allCases.firstIndex(of: selectedMonth) ?? 0
        let targetMonth = monthIndex + 1

        return transactions.filter { transaction in
            let transactionMonth = calendar.component(.month, from: transaction.date)
            let transactionYear = calendar.component(.year, from: transaction.date)
            return transactionMonth == targetMonth && transactionYear == selectedYear
        }
    }

    private func budgetForCategory(_ categoryModel: CategoryModel) -> Double {
        let monthIndex = Month.allCases.firstIndex(of: selectedMonth) ?? 0
        let targetMonth = monthIndex + 1

        if let monthlyOverride = monthlyBudgets.first(where: {
            $0.categoryID == categoryModel.id && $0.month == targetMonth && $0.year == selectedYear
        }) {
            return monthlyOverride.budgetLimit
        }
        return categoryModel.budgetLimit
    }

    private func spentInCategory(_ categoryModel: CategoryModel) -> Double {
        // Find transactions that match this category's ID (which corresponds to enum rawValue)
        let spent =
            currentMonthTransactions
            .filter { $0.category.rawValue == categoryModel.id && $0.type == .expense }
            .reduce(0) { $0 + abs($1.amount) }
        return spent
    }

    private var totalSpent: Double {
        displayCategories.reduce(0) { $0 + spentInCategory($1) }
    }

    private var totalBudget: Double {
        displayCategories.reduce(0) { $0 + budgetForCategory($1) }
    }

    private var projectedIncome: Double {
        // Try to fetch specific monthly income
        let monthIndex = Month.allCases.firstIndex(of: selectedMonth) ?? 0
        let targetMonth = monthIndex + 1

        if let incomeModel = monthlyIncomes.first(where: {
            $0.month == targetMonth && $0.year == selectedYear
        }) {
            return incomeModel.amount
        }

        // Fallback? Or default 0?
        // Let's assume if no record, we use the local string which defaults to "5000" initially or whatever user typed
        // Ideally we start with empty or 0 if nothing saved.
        // But to respect the "existing" logic, we can keep using manual entry.
        return Double(incomeString) ?? 0
    }

    private var freeCashFlow: Double {
        projectedIncome - totalBudget
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                ScrollView {
                    VStack(spacing: 24) {
                        // AI Insight Card
                        aiInsightCard

                        // Income
                        incomeSection

                        // Spending vs Budget (Edit Mode here)
                        spendingSection

                        // Summary
                        summaryCard
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $editingCategoryModel) { categoryModel in
            budgetEditSheet(for: categoryModel)
                .alert("Update Income", isPresented: $showingIncomeAlert) {
                    TextField("Amount", text: $tempIncomeString)
                        .keyboardType(.decimalPad)
                    Button("Cancel", role: .cancel) {}
                    Button("Save") {
                        saveIncome(tempIncomeString)
                    }
                } message: {
                    Text(
                        "Enter your expected income for \(selectedMonth.rawValue) \(String(selectedYear))."
                    )
                }
        }
        .sheet(isPresented: $showingAddCategorySheet) {
            AddCategorySheet()
        }
        .background(
            Color.clear
                .sheet(isPresented: $showingIconPicker) {
                    IconPickerView { iconName in
                        if let cat = categoryToCustomize {
                            cat.icon = iconName
                        }
                        showingIconPicker = false
                    }
                }
        )
        .onChange(of: selectedMonth) { _, _ in updateIncomeString() }
        .onChange(of: selectedYear) { _, _ in updateIncomeString() }
        .onChange(of: incomeString) { _, newValue in saveIncome(newValue) }
        .onAppear { updateIncomeString() }
    }

    // MARK: - Income Logic

    private func updateIncomeString() {
        let monthIndex = Month.allCases.firstIndex(of: selectedMonth) ?? 0
        let targetMonth = monthIndex + 1

        if let incomeModel = monthlyIncomes.first(where: {
            $0.month == targetMonth && $0.year == selectedYear
        }) {
            incomeString = String(format: "%.0f", incomeModel.amount)
        } else {
            incomeString = "5000"
        }
    }

    private func saveIncome(_ value: String) {
        let monthIndex = Month.allCases.firstIndex(of: selectedMonth) ?? 0
        let targetMonth = monthIndex + 1
        let amount = Double(value) ?? 0

        if let incomeModel = monthlyIncomes.first(where: {
            $0.month == targetMonth && $0.year == selectedYear
        }) {
            incomeModel.amount = amount
        } else {
            let newIncome = MonthlyIncomeModel(
                month: targetMonth, year: selectedYear, amount: amount)
            modelContext.insert(newIncome)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Monthly Planner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()

                // Year Menu
                Menu {
                    Button("2025") { selectedYear = 2025 }
                    Button("2026") { selectedYear = 2026 }
                    Button("2027") { selectedYear = 2027 }
                } label: {
                    HStack(spacing: 4) {
                        Text(String(selectedYear))
                            .font(.headline)
                            .fontWeight(.bold)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.zenithBlack)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.mintGreen))
                }
            }
            .padding(.horizontal)

            // Month Horizontal Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(Month.allCases) { month in
                        Button(action: {
                            withAnimation {
                                selectedMonth = month
                            }
                        }) {
                            Text(month.rawValue)
                                .font(
                                    .system(
                                        size: 16, weight: selectedMonth == month ? .bold : .medium)
                                )
                                .foregroundColor(selectedMonth == month ? .black : .white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    Capsule()
                                        .fill(
                                            selectedMonth == month
                                                ? Color.mintGreen : Color.white.opacity(0.1))
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 40)
        .padding(.bottom, 10)
    }

    // MARK: - AI Insight

    @ViewBuilder
    private var aiInsightCard: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.neonTurquoise)
            Text(aiAdvice)
                .font(.subheadline)
                .italic()
                .foregroundColor(.white)
                .opacity(0.9)
            Spacer()
            if isAnalyzing {
                ProgressView()
                    .tint(.neonTurquoise)
            } else {
                Button(action: analyzeSpending) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.neonTurquoise, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .background(Color(white: 1.0, opacity: 0.03))
        )
    }

    // MARK: - Income

    @ViewBuilder
    private var incomeSection: some View {
        Button(action: {
            tempIncomeString = incomeString
            showingIncomeAlert = true
            HapticManager.shared.medium()
        }) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.mintGreen.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.mintGreen)
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Income Goal")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)

                    Text("$\(Int(projectedIncome))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                Spacer()

                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Spending Section (Main Edit Area)

    @ViewBuilder
    private var spendingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.orange)
                Text("Spending vs Budget")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button(action: { showingAddCategorySheet = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.neonTurquoise)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            VStack(spacing: 16) {
                ForEach(displayCategories) { categoryModel in
                    VStack(spacing: 16) {
                        BudgetProgressRow(
                            title: categoryModel.name,
                            icon: categoryModel.icon,
                            spent: spentInCategory(categoryModel),
                            budget: budgetForCategory(categoryModel),
                            onTap: {
                                editingCategoryModel = categoryModel
                                budgetEditValue = String(Int(budgetForCategory(categoryModel)))
                                nameEditValue = categoryModel.name
                                return
                            }
                        )

                        if categoryModel != displayCategories.last {
                            Divider().background(Color(white: 1.0, opacity: 0.1))
                        }
                    }
                }
            }
            .padding()
            .background(Color(white: 1.0, opacity: 0.05))
            .cornerRadius(16)
        }
    }

    // MARK: - Restore Hidden Section (Edit Mode Only)

    // MARK: - Summary Card

    @ViewBuilder
    private var summaryCard: some View {
        VStack(spacing: 20) {
            Text("Financial Harmony")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("Income")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(Int(projectedIncome))")
                        .font(.headline)
                        .foregroundColor(.mintGreen)
                }

                VStack(spacing: 4) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(Int(totalSpent))")
                        .font(.headline)
                        .foregroundColor(.orange)
                }

                VStack(spacing: 4) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(Int(totalBudget))")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }

            Divider().background(Color(white: 1.0, opacity: 0.2))

            VStack(spacing: 8) {
                Text("Free Cash Flow")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(freeCashFlow >= 0 ? "$\(Int(freeCashFlow))" : "-$\(Int(abs(freeCashFlow)))")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(freeCashFlow >= 0 ? .mintGreen : .red)

                Text(freeCashFlow >= 0 ? "Safe to spend on wants" : "You are over budget!")
                    .font(.caption)
                    .foregroundColor(freeCashFlow >= 0 ? .mintGreen : .red)
            }

            // Harmony Indicator
            HStack {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(
                            index < Int(Double(freeCashFlow > 0 ? 5 : 2))
                                ? Color.mintGreen : Color.gray.opacity(0.3)
                        )
                        .frame(width: 8, height: 8)
                }
                Text("Harmony Score")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.zenithCharcoal.opacity(0.8) as Color)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            freeCashFlow >= 0
                                ? Color.mintGreen.opacity(0.3) as Color
                                : Color.red.opacity(0.3) as Color,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: freeCashFlow >= 0
                        ? Color.mintGreen.opacity(0.2) as Color : Color.red.opacity(0.2) as Color,
                    radius: 20
                )
        )
        .padding(.bottom, 40)
    }

    // MARK: - Budget & Name Edit Sheet

    private func budgetEditSheet(for categoryModel: CategoryModel) -> some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Customize Category")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Icon preview
                Image(systemName: categoryModel.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.neonTurquoise)
                    .padding()
                    .background(Circle().fill(Color.white.opacity(0.1)))

                VStack(spacing: 16) {
                    // Rename Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category Name")
                            .font(.caption)
                            .foregroundColor(.gray)

                        TextField("Name (e.g. Sushi)", text: $nameEditValue)
                            .foregroundColor(.white)
                            .font(.title3)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }

                    // Budget Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Limit")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            Text("$")
                                .foregroundColor(.gray)
                                .font(.title3)
                            TextField("Budget", text: $budgetEditValue)
                                .keyboardType(.decimalPad)
                                .foregroundColor(.white)
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button(action: {
                    if let value = Double(budgetEditValue) {
                        let monthIndex = Month.allCases.firstIndex(of: selectedMonth) ?? 0
                        let targetMonth = monthIndex + 1

                        // Check if we already have a monthly budget for this category/month/year
                        if let existing = monthlyBudgets.first(where: {
                            $0.categoryID == categoryModel.id && $0.month == targetMonth
                                && $0.year == selectedYear
                        }) {
                            existing.budgetLimit = value
                        } else {
                            // Create new override
                            let newBudget = MonthlyBudgetModel(
                                categoryID: categoryModel.id,
                                month: targetMonth,
                                year: selectedYear,
                                budgetLimit: value
                            )
                            modelContext.insert(newBudget)
                        }
                    }
                    if !nameEditValue.isEmpty {
                        categoryModel.name = nameEditValue
                    }
                    editingCategoryModel = nil
                }) {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mintGreen)
                        .cornerRadius(16)
                }
                .padding(.horizontal)

                Button(action: { editingCategoryModel = nil }) {
                    Text("Cancel")
                        .foregroundColor(.gray)
                }
                .padding(.bottom)
            }
            .padding(.top, 40)
        }
    }

    // MARK: - AI Analysis (Using new model logic)

    private func analyzeSpending() {
        isAnalyzing = true
        let spentPercent = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0
        var highestCategoryName: String = "Unknown"
        var highestSpent: Double = 0

        for categoryModel in displayCategories {
            let spent = spentInCategory(categoryModel)
            if spent > highestSpent {
                highestSpent = spent
                highestCategoryName = categoryModel.name
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if spentPercent > 80 {
                aiAdvice =
                    "⚠️ You've used \(Int(spentPercent))% of your budget. Watch \(highestCategoryName)!"
            } else if spentPercent > 50 {
                aiAdvice =
                    "📊 \(Int(spentPercent))% spent. \(highestCategoryName) is your top category."
            } else if totalSpent == 0 {
                aiAdvice = "🎯 No spending tracked yet this month. Add transactions to see insights!"
            } else {
                aiAdvice = "✅ On track! Only \(Int(spentPercent))% of budget used so far."
            }
            isAnalyzing = false
        }
    }
}

// MARK: - Subcomponents

struct BudgetProgressRow: View {
    let title: String
    let icon: String
    let spent: Double
    let budget: Double
    let onTap: () -> Void

    private var progress: Double {
        guard budget > 0 else { return 0 }
        return min(spent / budget, 1.0)
    }

    // Gradient colors for progress (Zenith Style)
    private var progressGradient: LinearGradient {
        if progress >= 0.9 {
            return LinearGradient(
                colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        } else if progress >= 0.7 {
            return LinearGradient(
                colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(
                colors: [.mintGreen, .neonTurquoise], startPoint: .leading, endPoint: .trailing)
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                HStack {
                    Label {
                        Text(title).foregroundColor(.white)
                    } icon: {
                        Image(systemName: icon).foregroundColor(.white)
                    }
                    .font(.subheadline)

                    Spacer()

                    Text("$\(Int(spent)) / $\(Int(budget))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(white: 1.0, opacity: 0.08))
                            .frame(height: 6)

                        // Active Progress with Glow
                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressGradient)
                            .frame(width: geometry.size.width * progress, height: 6)
                            .shadow(
                                color: progress >= 0.9
                                    ? Color.red.opacity(0.5) as Color
                                    : Color.mintGreen.opacity(0.3) as Color,
                                radius: 4, x: 0,
                                y: 0)
                    }
                }
                .frame(height: 6)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Icon Picker

struct IconPickerView: View {
    let onSelect: (String) -> Void
    @Environment(\.presentationMode) var presentationMode

    let icons = [
        "cart.fill", "car.fill", "house.fill", "bolt.fill", "leaf.fill",
        "gamecontroller.fill", "airplane", "cross.case.fill", "book.fill",
        "graduationcap.fill", "gift.fill", "creditcard.fill", "banknote.fill",
        "cup.and.saucer.fill", "fork.knife", "tshirt.fill", "bag.fill",
        "drop.fill", "flame.fill", "lightbulb.fill", "briefcase.fill",
        "pawprint.fill", "ticket.fill", "music.note", "building.columns.fill",
        "bus.fill", "fuelpump.fill", "bed.double.fill", "scissors",
        "bicycle", "tram.fill", "desktopcomputer", "keyboard.fill",
        "printer.fill", "headphones", "camera.fill", "photo.fill",
        "paintpalette.fill", "hammer.fill", "wrench.and.screwdriver.fill",
    ]

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack {
                Text("Select Icon")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 20) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: {
                            onSelect(icon)
                        }) {
                            Image(systemName: icon)
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color(white: 1.0, opacity: 0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()

                Spacer()
            }
        }
    }
}

#Preview {
    ZenithPlannerView(transactions: [])
}
