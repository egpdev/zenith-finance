import SwiftData
import SwiftUI

struct ZenithPlannerView: View {
    let transactions: [ZenithTransaction]

    @Query(sort: \CategoryModel.orderIndex) private var categories: [CategoryModel]
    @Query private var monthlyBudgets: [MonthlyBudgetModel]
    @Query private var monthlyIncomes: [MonthlyIncomeModel]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedMonth: Month = {
        let monthInt = Calendar.current.component(.month, from: Date())
        let months = Month.allCases
        return months.count >= monthInt ? months[monthInt - 1] : .january
    }()
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    @State private var showingIncomeAlert = false
    @State private var tempIncomeString = ""
    @State private var showingAddCategorySheet = false
    @State private var editingCategoryModel: CategoryModel?
    @State private var budgetEditValue: String = ""
    @State private var nameEditValue: String = ""

    // AI Analysis
    @State private var showingAIInsight = false
    @State private var aiInsight: String = ""
    @State private var isAnalyzing = false

    // MARK: - Computed

    private var displayCategories: [CategoryModel] {
        categories.filter { !$0.isHidden }
    }

    private var currentMonthTransactions: [ZenithTransaction] {
        let calendar = Calendar.current
        let monthIndex = Month.allCases.firstIndex(of: selectedMonth) ?? 0
        let targetMonth = monthIndex + 1
        return transactions.filter { t in
            calendar.component(.month, from: t.date) == targetMonth
                && calendar.component(.year, from: t.date) == selectedYear
        }
    }

    private func budgetForCategory(_ cat: CategoryModel) -> Double {
        let monthIndex = Month.allCases.firstIndex(of: selectedMonth) ?? 0
        let targetMonth = monthIndex + 1
        if let override = monthlyBudgets.first(where: {
            $0.categoryID == cat.id && $0.month == targetMonth && $0.year == selectedYear
        }) {
            return override.budgetLimit
        }
        return cat.budgetLimit
    }

    private func spentInCategory(_ cat: CategoryModel) -> Double {
        currentMonthTransactions
            .filter { $0.category.rawValue == cat.id && $0.type == .expense }
            .reduce(0) { $0 + abs($1.amount) }
    }

    private var totalBudget: Double {
        displayCategories.reduce(0) { $0 + budgetForCategory($1) }
    }

    private var totalSpent: Double {
        displayCategories.reduce(0) { $0 + spentInCategory($1) }
    }

    private var income: Double {
        let monthIndex = Month.allCases.firstIndex(of: selectedMonth) ?? 0
        let targetMonth = monthIndex + 1
        return monthlyIncomes.first(where: {
            $0.month == targetMonth && $0.year == selectedYear
        })?.amount ?? 5000
    }

    private var freeCash: Double {
        income - totalBudget
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ZenithBackground()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    monthHeader
                        .padding(.top, 20)
                        .padding(.bottom, 24)

                    // Income Card
                    incomeCard
                        .padding(.horizontal)
                        .padding(.bottom, 16)

                    // AI Insight Button
                    aiInsightButton
                        .padding(.horizontal)
                        .padding(.bottom, 20)

                    // Budget Section
                    budgetSection
                        .padding(.horizontal)

                    // Summary Footer
                    summaryFooter
                        .padding(.horizontal)
                        .padding(.top, 24)
                        .padding(.bottom, 100)
                }
            }
        }
        .sheet(item: $editingCategoryModel) { cat in
            categoryEditSheet(for: cat)
        }
        .sheet(isPresented: $showingAddCategorySheet) {
            AddCategorySheet()
        }
        .alert("Set Monthly Income", isPresented: $showingIncomeAlert) {
            TextField("Amount", text: $tempIncomeString)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) {}
            Button("Save") { saveIncome() }
        } message: {
            Text("How much do you expect to earn in \(selectedMonth.rawValue)?")
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button(action: prevMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(selectedMonth.rawValue)
                    .font(.title.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.neonTurquoise.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Menu {
                    ForEach(2024...2027, id: \.self) { year in
                        Button(String(year)) { selectedYear = year }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(String(selectedYear))
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.gray)
                }
            }

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Income Card

    private var incomeCard: some View {
        Button(action: {
            tempIncomeString = String(Int(income))
            showingIncomeAlert = true
            HapticManager.shared.light()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("EXPECTED INCOME")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.mintGreen.opacity(0.8))

                    Text("$\(Int(income))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.mintGreen.opacity(0.5))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.mintGreen.opacity(0.5), Color.mintGreen.opacity(0.1),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.mintGreen.opacity(0.15), radius: 15, x: 0, y: 8)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - AI Insight Button

    private var aiInsightButton: some View {
        Button(action: analyzeAndShowInsight) {
            HStack(spacing: 12) {
                // AI Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.neonTurquoise.opacity(0.2), Color.purple.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(.neonTurquoise)
                        .rotationEffect(.degrees(isAnalyzing ? 360 : 0))
                        .animation(
                            isAnalyzing
                                ? .linear(duration: 2).repeatForever(autoreverses: false)
                                : .default,
                            value: isAnalyzing
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Budget Advisor")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    Text(showingAIInsight ? aiInsight : "Tap to get personalized advice")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.neonTurquoise.opacity(0.4), Color.purple.opacity(0.2),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.neonTurquoise.opacity(0.1), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func analyzeAndShowInsight() {
        isAnalyzing = true
        HapticManager.shared.light()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let spentPercent = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0
            let savingsRate = income > 0 ? (freeCash / income) * 100 : 0

            // Find highest spending category
            var highestCat = ""
            var highestSpent: Double = 0
            for cat in displayCategories {
                let spent = spentInCategory(cat)
                if spent > highestSpent {
                    highestSpent = spent
                    highestCat = cat.name
                }
            }

            if totalBudget == 0 {
                aiInsight =
                    "💡 Start by setting budgets for your categories to get personalized insights!"
            } else if freeCash < 0 {
                aiInsight =
                    "⚠️ Your budgets exceed your income by $\(Int(abs(freeCash))). Consider reducing \(highestCat.isEmpty ? "some categories" : highestCat)."
            } else if savingsRate < 10 {
                aiInsight =
                    "📊 You're saving \(Int(savingsRate))% of income. Try to aim for at least 20% for a healthy financial cushion."
            } else if spentPercent > 80 {
                aiInsight =
                    "🔥 You've used \(Int(spentPercent))% of your budget. Watch your spending on \(highestCat)!"
            } else if spentPercent > 50 {
                aiInsight =
                    "👍 Halfway through your budget (\(Int(spentPercent))%). You're on track!"
            } else if totalSpent == 0 {
                aiInsight =
                    "✨ No spending yet. Your free cash is $\(Int(freeCash)) — great savings rate of \(Int(savingsRate))%!"
            } else {
                aiInsight =
                    "✅ Great job! Only \(Int(spentPercent))% budget used. Savings rate: \(Int(savingsRate))%."
            }

            showingAIInsight = true
            isAnalyzing = false
        }
    }

    // MARK: - Budget Section

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BUDGET ALLOCATION")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)

                    Text("Tap a category to set its limit")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.6))
                }

                Spacer()

                Button(action: { showingAddCategorySheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.neonTurquoise)
                }
            }

            // Category List
            if displayCategories.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.4))

                    Text("No budget categories yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Button(action: { showingAddCategorySheet = true }) {
                        Text("Add Your First Category")
                            .font(.subheadline.bold())
                            .foregroundColor(.neonTurquoise)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(displayCategories) { cat in
                        BudgetRow(
                            icon: cat.icon,
                            name: cat.name,
                            budget: budgetForCategory(cat),
                            spent: spentInCategory(cat),
                            onTap: {
                                editingCategoryModel = cat
                                budgetEditValue = String(Int(budgetForCategory(cat)))
                                nameEditValue = cat.name
                            },
                            onDelete: {
                                deleteCategory(cat)
                            }
                        )

                        if cat.id != displayCategories.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                )
            }
        }
    }

    // MARK: - Summary Footer

    private var summaryFooter: some View {
        VStack(spacing: 16) {
            // Divider line
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            HStack {
                // Total Budgeted
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Budgeted")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(Int(totalBudget))")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }

                Spacer()

                // Spent so far
                VStack(spacing: 4) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(Int(totalSpent))")
                        .font(.title3.bold())
                        .foregroundColor(.orange)
                }

                Spacer()

                // Free Cash
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Free Cash")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(freeCash >= 0 ? "$\(Int(freeCash))" : "-$\(Int(abs(freeCash)))")
                        .font(.title3.bold())
                        .foregroundColor(freeCash >= 0 ? .mintGreen : .red)
                }
            }

            // Status Message
            if freeCash < 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("You've allocated more than your income!")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                )
            } else if totalBudget == 0 {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.neonTurquoise)
                    Text("Start by adding categories and setting budgets")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.neonTurquoise.opacity(0.1))
                )
            }
        }
    }

    // MARK: - Helpers

    private func prevMonth() {
        if let i = Month.allCases.firstIndex(of: selectedMonth), i > 0 {
            withAnimation { selectedMonth = Month.allCases[i - 1] }
        } else {
            withAnimation {
                selectedMonth = Month.allCases.last!
                selectedYear -= 1
            }
        }
    }

    private func nextMonth() {
        if let i = Month.allCases.firstIndex(of: selectedMonth), i < Month.allCases.count - 1 {
            withAnimation { selectedMonth = Month.allCases[i + 1] }
        } else {
            withAnimation {
                selectedMonth = Month.allCases.first!
                selectedYear += 1
            }
        }
    }

    private func saveIncome() {
        let monthIndex = Month.allCases.firstIndex(of: selectedMonth) ?? 0
        let targetMonth = monthIndex + 1
        let amount = Double(tempIncomeString) ?? 0

        if let existing = monthlyIncomes.first(where: {
            $0.month == targetMonth && $0.year == selectedYear
        }) {
            existing.amount = amount
        } else {
            modelContext.insert(
                MonthlyIncomeModel(month: targetMonth, year: selectedYear, amount: amount))
        }
    }

    // MARK: - Category Edit Sheet

    private func categoryEditSheet(for cat: CategoryModel) -> some View {
        ZStack {
            ZenithBackground()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Button("Cancel") { editingCategoryModel = nil }
                        .foregroundColor(.gray)
                    Spacer()
                    Text("Edit Category")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Save") {
                        saveCategory(cat)
                        editingCategoryModel = nil
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.mintGreen)
                }
                .padding()

                // Icon
                Image(systemName: cat.icon)
                    .font(.system(size: 48))
                    .foregroundColor(.neonTurquoise)
                    .padding(24)
                    .background(Circle().fill(Color.white.opacity(0.1)))

                // Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Name", text: $nameEditValue)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Budget Limit")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack {
                            Text("$")
                                .foregroundColor(.gray)
                            TextField("0", text: $budgetEditValue)
                                .keyboardType(.decimalPad)
                                .foregroundColor(.white)
                                .font(.title2.bold())
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Delete Button
                Button(action: {
                    deleteCategory(cat)
                    editingCategoryModel = nil
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Category")
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func deleteCategory(_ cat: CategoryModel) {
        modelContext.delete(cat)
        HapticManager.shared.light()
    }

    private func saveCategory(_ cat: CategoryModel) {
        if let value = Double(budgetEditValue) {
            let monthIndex = Month.allCases.firstIndex(of: selectedMonth) ?? 0
            let targetMonth = monthIndex + 1

            if let existing = monthlyBudgets.first(where: {
                $0.categoryID == cat.id && $0.month == targetMonth && $0.year == selectedYear
            }) {
                existing.budgetLimit = value
            } else {
                modelContext.insert(
                    MonthlyBudgetModel(
                        categoryID: cat.id,
                        month: targetMonth,
                        year: selectedYear,
                        budgetLimit: value
                    ))
            }
        }
        if !nameEditValue.isEmpty {
            cat.name = nameEditValue
        }
    }
}

// MARK: - Budget Row

struct BudgetRow: View {
    let icon: String
    let name: String
    let budget: Double
    let spent: Double
    let onTap: () -> Void
    let onDelete: () -> Void

    private var progress: Double {
        guard budget > 0 else { return 0 }
        return min(spent / budget, 1.0)
    }

    private var progressColor: Color {
        if progress >= 0.9 {
            return .red
        } else if progress >= 0.7 {
            return .orange
        } else {
            return .mintGreen
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(.white)
                }

                // Name & Progress
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)

                        Spacer()

                        Text("$\(Int(spent)) / $\(Int(budget))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(progressColor)
                                .frame(width: geo.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Icon Picker (kept for AddCategorySheet)

struct IconPickerView: View {
    let onSelect: (String) -> Void
    @Environment(\.presentationMode) var presentationMode

    let icons = [
        "cart.fill", "car.fill", "house.fill", "bolt.fill", "leaf.fill",
        "gamecontroller.fill", "airplane", "cross.case.fill", "book.fill",
        "fork.knife", "tshirt.fill", "bag.fill", "drop.fill", "flame.fill",
    ]

    var body: some View {
        ZStack {
            ZenithBackground()

            VStack {
                Text("Select Icon")
                    .font(.title2.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.neonTurquoise],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.top, 24)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            onSelect(icon)
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    Color.neonTurquoise.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                .padding()
                Spacer()
            }
        }
    }
}
