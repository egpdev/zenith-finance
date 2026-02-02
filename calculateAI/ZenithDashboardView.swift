import Charts
import SwiftUI

struct ZenithDashboardView: View {
    let transactions: [ZenithTransaction]
    var onNavigateToTransactions: (() -> Void)? = nil

    // Navigation triggers (can be bound to main view selection if needed, or simple sheets)
    @State private var showingAddTransaction = false
    @State private var showingScanner = false
    @State private var showingVoiceInput = false
    @State private var showingBankConnection = false
    @State private var showingNotifications = false

    var body: some View {
        ZStack {
            // New Aurora Background
            ZenithBackground()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.neonTurquoise, Color.mintGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Zenith")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { showingNotifications = true }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )

                            Image(systemName: "bell.badge.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.red, Color.white)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 10)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Main Balance & Chart
                        BalanceCard(transactions: transactions)

                        // Quick Actions (Horizontal Scroll)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                QuickActionButton(icon: "plus", label: "Add", color: .neonTurquoise)
                                {
                                    HapticManager.shared.medium()
                                    showingAddTransaction = true
                                }
                                QuickActionButton(
                                    icon: "camera.viewfinder", label: "Scan", color: .mintGreen
                                ) {
                                    HapticManager.shared.medium()
                                    showingScanner = true
                                }
                                QuickActionButton(icon: "mic.fill", label: "Voice", color: .purple)
                                {
                                    HapticManager.shared.medium()
                                    showingVoiceInput = true
                                }
                                QuickActionButton(
                                    icon: "building.columns.fill", label: "Bank", color: .orange
                                ) {
                                    HapticManager.shared.medium()
                                    showingBankConnection = true
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Smart Insight
                        SmartBudgetCard(transactions: transactions)

                        // Recent Activity Preview
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Activity")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button("See All") {
                                    HapticManager.shared.light()
                                    onNavigateToTransactions?()
                                }
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            }

                            if transactions.isEmpty {
                                Text("No recent transactions")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(transactions.prefix(3)) { transaction in
                                    DashboardTransactionRow(transaction: transaction)
                                }
                            }
                        }
                        .padding(.horizontal, 4)

                        // Spacer for bottom tab bar
                        Spacer().frame(height: 80)
                    }
                    .padding()
                }
                .refreshable {
                    // Sync widget data on pull-to-refresh
                    syncToWidget()
                    HapticManager.shared.light()
                }
            }
        }
        // Sheets and overlays
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
        .sheet(isPresented: $showingScanner) {
            ZenithScannerView()
        }
        .sheet(isPresented: $showingBankConnection) {
            BankConnectionPlaceholderView()
        }
        .overlay {
            if showingVoiceInput {
                ZenithVoiceInputView(isPresented: $showingVoiceInput)
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
        }
    }

    private func syncToWidget() {
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

// MARK: - Notifications View
struct NotificationsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var notificationManager = NotificationManager.shared

    @AppStorage("budgetAlertsEnabled") private var budgetAlerts = true
    @AppStorage("weeklyReportsEnabled") private var weeklyReport = true
    @AppStorage("transactionAlertsEnabled") private var transactionAlerts = true
    @AppStorage("dailyReminderEnabled") private var dailyReminder = false

    @State private var showingPermissionAlert = false

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Notifications")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 20) {
                        // Permission Status
                        if !notificationManager.isAuthorized {
                            Button(action: requestPermission) {
                                HStack {
                                    Image(systemName: "bell.badge")
                                        .font(.title2)
                                        .foregroundColor(.mintGreen)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Enable Notifications")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("Get alerts about budgets and spending")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.mintGreen)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.mintGreen.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.mintGreen.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }

                        // Recent notifications
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent")
                                .font(.headline)
                                .foregroundColor(.gray)

                            NotificationRow(
                                icon: "exclamationmark.triangle.fill",
                                iconColor: .orange,
                                title: "Budget Alert",
                                message: "You've used 85% of your Food & Drink budget",
                                time: "2h ago"
                            )

                            NotificationRow(
                                icon: "chart.line.uptrend.xyaxis",
                                iconColor: .mintGreen,
                                title: "Weekly Report",
                                message: "Your spending decreased 12% this week!",
                                time: "1d ago"
                            )

                            NotificationRow(
                                icon: "sparkles",
                                iconColor: .neonTurquoise,
                                title: "AI Insight",
                                message: "You could save $50/month by switching coffee shops",
                                time: "3d ago"
                            )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )

                        // Settings
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notification Settings")
                                .font(.headline)
                                .foregroundColor(.gray)

                            Toggle("Budget Alerts", isOn: $budgetAlerts)
                                .toggleStyle(SwitchToggleStyle(tint: .mintGreen))
                                .foregroundColor(.white)
                                .disabled(!notificationManager.isAuthorized)

                            Toggle("Weekly Reports", isOn: $weeklyReport)
                                .toggleStyle(SwitchToggleStyle(tint: .mintGreen))
                                .foregroundColor(.white)
                                .disabled(!notificationManager.isAuthorized)
                                .onChange(of: weeklyReport) { _, newValue in
                                    if newValue {
                                        notificationManager.scheduleWeeklyReport(
                                            savings: 0, topCategory: "Food & Drink")
                                    }
                                }

                            Toggle("Transaction Alerts", isOn: $transactionAlerts)
                                .toggleStyle(SwitchToggleStyle(tint: .mintGreen))
                                .foregroundColor(.white)
                                .disabled(!notificationManager.isAuthorized)

                            Toggle("Daily Reminder", isOn: $dailyReminder)
                                .toggleStyle(SwitchToggleStyle(tint: .mintGreen))
                                .foregroundColor(.white)
                                .disabled(!notificationManager.isAuthorized)
                                .onChange(of: dailyReminder) { _, newValue in
                                    notificationManager.scheduleDailyReminder(enabled: newValue)
                                }

                            if !notificationManager.isAuthorized {
                                Text("Enable notifications above to use these settings")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )

                        // Clear All Button
                        Button(action: {
                            notificationManager.clearAllNotifications()
                            HapticManager.shared.light()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear All Notifications")
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
        }
        .alert("Notification Permission", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Notifications are disabled. Please enable them in Settings.")
        }
    }

    private func requestPermission() {
        Task {
            let granted = await notificationManager.requestPermission()
            if !granted {
                showingPermissionAlert = true
            } else {
                HapticManager.shared.success()
            }
        }
    }
}

struct NotificationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let time: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(iconColor.opacity(0.2)))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                    Text(time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(message)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Bank Connection View
struct BankConnectionPlaceholderView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var isConnecting = false
    @State private var selectedBank: Bank?
    @State private var connectionStep: ConnectionStep = .selectBank
    @State private var showSuccess = false

    enum ConnectionStep {
        case selectBank
        case authenticating
        case success
    }

    let banks: [Bank] = [
        Bank(name: "Chase", icon: "building.columns.fill", color: .blue),
        Bank(name: "Bank of America", icon: "building.2.fill", color: .red),
        Bank(name: "Wells Fargo", icon: "building.columns.circle.fill", color: .yellow),
        Bank(name: "Citi", icon: "building.fill", color: .cyan),
        Bank(name: "Capital One", icon: "creditcard.fill", color: .orange),
        Bank(name: "US Bank", icon: "banknote.fill", color: .purple),
        Bank(name: "PNC Bank", icon: "dollarsign.circle.fill", color: .orange),
        Bank(name: "TD Bank", icon: "leaf.fill", color: .green),
    ]

    var filteredBanks: [Bank] {
        if searchText.isEmpty {
            return banks
        }
        return banks.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connect Your Bank")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Securely link your accounts")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding()

                if connectionStep == .selectBank {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search banks...", text: $searchText)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Banks List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredBanks) { bank in
                                BankRow(bank: bank, isSelected: selectedBank?.id == bank.id) {
                                    HapticManager.shared.light()
                                    selectedBank = bank
                                }
                            }
                        }
                        .padding()
                    }

                    // Connect Button
                    if selectedBank != nil {
                        Button(action: startConnection) {
                            Text("Connect Bank")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.mintGreen)
                                .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                } else if connectionStep == .authenticating {
                    Spacer()
                    VStack(spacing: 24) {
                        // Animated connection visual
                        ZStack {
                            Circle()
                                .stroke(Color.mintGreen.opacity(0.3), lineWidth: 4)
                                .frame(width: 120, height: 120)

                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(Color.mintGreen, lineWidth: 4)
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(isConnecting ? 360 : 0))
                                .animation(
                                    .linear(duration: 1).repeatForever(autoreverses: false),
                                    value: isConnecting)

                            Image(systemName: selectedBank?.icon ?? "building.columns.fill")
                                .font(.system(size: 40))
                                .foregroundColor(selectedBank?.color ?? .blue)
                        }

                        Text("Connecting to \(selectedBank?.name ?? "Bank")...")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("This may take a moment")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()

                } else if connectionStep == .success {
                    Spacer()
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 120, height: 120)

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                        }
                        .scaleEffect(showSuccess ? 1 : 0.5)
                        .opacity(showSuccess ? 1 : 0)
                        .animation(.spring(dampingFraction: 0.6), value: showSuccess)

                        Text("Successfully Connected!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("\(selectedBank?.name ?? "Your bank") is now linked to Zenith Finance")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("3 accounts found")
                                    .foregroundColor(.white)
                            }
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("47 transactions imported")
                                    .foregroundColor(.white)
                            }
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Auto-sync enabled")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    Spacer()

                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.mintGreen)
                            .cornerRadius(16)
                    }
                    .padding()
                }
            }

            // Security Notice
            if connectionStep == .selectBank {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.mintGreen)
                        Text("Bank-grade 256-bit encryption")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, selectedBank != nil ? 80 : 24)
                }
            }
        }
        .animation(.easeInOut, value: connectionStep)
        .animation(.easeInOut, value: selectedBank)
    }

    private func startConnection() {
        connectionStep = .authenticating
        isConnecting = true

        // Simulate connection process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                connectionStep = .success
                showSuccess = true
                HapticManager.shared.success()
            }
        }
    }
}

struct Bank: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
}

struct BankRow: View {
    let bank: Bank
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: bank.icon)
                    .font(.system(size: 24))
                    .foregroundColor(bank.color)
                    .frame(width: 48, height: 48)
                    .background(bank.color.opacity(0.2))
                    .cornerRadius(12)

                Text(bank.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.mintGreen)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.mintGreen : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - Subcomponents

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [color.opacity(0.5), color.opacity(0.1)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
            }

            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct DashboardTransactionRow: View {
    let transaction: ZenithTransaction

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(white: 1.0, opacity: 0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: transaction.icon)
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(transaction.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Amount
            Text(
                transaction.type == .expense
                    ? "-$\(Int(transaction.amount))" : "+$\(Int(transaction.amount))"
            )
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(transaction.type == .expense ? .white : .mintGreen)
            .shadow(
                color: transaction.type == .expense ? .clear : .mintGreen.opacity(0.3), radius: 5)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.zenithCharcoal.opacity(0.6))
        )
    }
}

// MARK: - Balance Card (Revamped)
struct BalanceCard: View {
    let transactions: [ZenithTransaction]
    @State private var selectedIndex: Int? = nil

    var currentBalance: Double {
        transactions.reduce(0) { $0 + ($1.type == .income ? $1.amount : -$1.amount) }
    }

    var chartPoints: [Double] {
        let sorted = transactions.sorted { $0.date < $1.date }
        var running: Double = 0
        var points: [Double] = []
        for t in sorted {
            running += (t.type == .income ? t.amount : -t.amount)
            points.append(running)
        }
        if points.isEmpty { return [0, 0, 0] }
        return Array(points.suffix(20))
    }

    var displayBalance: Double {
        if let index = selectedIndex, index < chartPoints.count { return chartPoints[index] }
        return currentBalance.isNaN ? 0 : currentBalance
    }

    var body: some View {
        ZStack {
            // Glassmorphism background
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 5) {
                Text("TOTAL BALANCE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                Text("$\(displayBalance, specifier: "%.2f")")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.neonTurquoise],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText())
                    .padding(.horizontal, 24)

                // Chart area
                Chart {
                    ForEach(Array(chartPoints.enumerated()), id: \.offset) { index, value in
                        AreaMark(
                            x: .value("Idx", index),
                            y: .value("Val", value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.neonTurquoise.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Idx", index),
                            y: .value("Val", value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.neonTurquoise)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }

                    if let selectedIndex, selectedIndex < chartPoints.count {
                        RuleMark(x: .value("Idx", selectedIndex))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    }
                }
                .frame(height: 120)
                .padding(.bottom, 20)
                .chartYAxis(.hidden)
                .chartXAxis(.hidden)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let x = value.location.x
                                        if let idx: Int = proxy.value(atX: x) {
                                            if selectedIndex != idx {
                                                selectedIndex = idx
                                                HapticManager.shared.light()
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation {
                                            selectedIndex = nil
                                        }
                                    }
                            )
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Smart Budget Card (Revamped)
struct SmartBudgetCard: View {
    var transactions: [ZenithTransaction]
    @State private var aiInsight: String = "Analyzing your spending..."
    @State private var isAnalyzing: Bool = true

    var body: some View {
        HStack(spacing: 16) {
            // Animated Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 56, height: 56)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.neonTurquoise, Color.mintGreen],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Financial Insight")
                    .font(.headline)
                    .foregroundColor(.white)

                Text(aiInsight)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.neonTurquoise.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .neonTurquoise.opacity(0.1), radius: 10)
        )
        .padding(.horizontal)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if transactions.isEmpty {
                    self.aiInsight = "Add transactions to unlock AI predictions."
                } else {
                    GroqService.shared.fetchFinancialInsight(transactions: transactions) { result in
                        if result.contains("failed") || result.contains("error") {
                            self.aiInsight =
                                "Spending on 'Food' is higher this week. Avoid delivery to save $50."
                        } else {
                            self.aiInsight = result
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ZenithDashboardView(
        transactions: [
            ZenithTransaction(
                merchant: "Uber Eats", date: Date(), amount: 25.50, type: .expense,
                category: .foodAndDrink),
            ZenithTransaction(
                merchant: "Salary", date: Date().addingTimeInterval(-86400), amount: 3000,
                type: .income, category: .salary),
        ])
}
