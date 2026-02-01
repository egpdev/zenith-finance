import SwiftData
import SwiftUI

// MARK: - Color Extension Helper for Serialization
extension Color {
    static let goalColors: [Color] = [.mintGreen, .neonTurquoise, .purple, .orange, .pink, .blue]
}

enum ZenithProfileDestination: String, Hashable {
    case account, goals, security, guide, help, recurring, cloud
}

struct ZenithProfileView: View {
    @State private var showLogoutAlert = false
    @State private var showingSubscription = false
    @State private var showingExport = false
    @State private var showingNameEdit = false
    @State private var tempName = ""

    @AppStorage("userName") private var userName = "Zenith User"

    @Query(sort: \ZenithTransaction.date, order: .reverse) private var transactions:
        [ZenithTransaction]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zenithBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Header
                    VStack(spacing: 20) {
                        // Avatar Ring
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.neonTurquoise.opacity(0.2), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.neonTurquoise, Color.mintGreen],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3
                                        )
                                        .shadow(color: .neonTurquoise.opacity(0.8), radius: 10)
                                )

                            Image(systemName: "person.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)

                        VStack(spacing: 8) {
                            Button(action: {
                                tempName = userName
                                showingNameEdit = true
                            }) {
                                HStack(spacing: 6) {
                                    Text(userName)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            Button(action: {
                                showingSubscription = true
                            }) {
                                Text("Premium Member")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.mintGreen)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.mintGreen.opacity(0.1))
                                            .overlay(
                                                Capsule()
                                                    .stroke(
                                                        Color.mintGreen.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.bottom, 40)

                    ScrollView {
                        VStack(spacing: 24) {
                            // MARK: - Zenith Score Card
                            ZenithScoreCard()

                            // MARK: - Menu Options
                            VStack(spacing: 16) {
                                NavigationLink(value: ZenithProfileDestination.account) {
                                    MenuRow(icon: "gearshape.fill", title: "Account Settings")
                                }
                                NavigationLink(value: ZenithProfileDestination.goals) {
                                    MenuRow(icon: "target", title: "Financial Goals")
                                }
                                NavigationLink(value: ZenithProfileDestination.security) {
                                    MenuRow(icon: "lock.shield.fill", title: "Security & Privacy")
                                }
                                NavigationLink(value: ZenithProfileDestination.guide) {
                                    MenuRow(
                                        icon: "sparkles.rectangle.stack.fill",
                                        title: "App Guide & AI Features")
                                }
                                NavigationLink(value: ZenithProfileDestination.help) {
                                    MenuRow(
                                        icon: "questionmark.circle.fill", title: "Help & Support")
                                }

                                // Recurring Transactions
                                NavigationLink(value: ZenithProfileDestination.recurring) {
                                    MenuRow(
                                        icon: "arrow.triangle.2.circlepath.circle.fill",
                                        title: "Recurring Transactions")
                                }

                                // iCloud Sync
                                NavigationLink(value: ZenithProfileDestination.cloud) {
                                    MenuRow(icon: "icloud.fill", title: "iCloud Sync")
                                }

                                // Export Data Button
                                Button(action: { showingExport = true }) {
                                    MenuRow(icon: "square.and.arrow.up.fill", title: "Export Data")
                                }
                            }

                            Spacer(minLength: 40)

                            // MARK: - Logout
                            Button(action: {
                                showLogoutAlert = true
                            }) {
                                Text("Log Out")
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.red.opacity(0.8))
                            }
                            .padding(.bottom, 40)
                            .alert("Log Out", isPresented: $showLogoutAlert) {
                                Button("Cancel", role: .cancel) {}
                                Button("Log Out", role: .destructive) {
                                    // Handle logout logic here
                                    print("User logged out")
                                }
                            } message: {
                                Text("Are you sure you want to log out of your account?")
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .sheet(isPresented: $showingSubscription) {
                ZenithSubscriptionView()
            }
            .sheet(isPresented: $showingExport) {
                DataExportView(transactions: transactions)
            }
            .alert("Edit Name", isPresented: $showingNameEdit) {
                TextField("Your name", text: $tempName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    if !tempName.trimmingCharacters(in: .whitespaces).isEmpty {
                        userName = tempName.trimmingCharacters(in: .whitespaces)
                    }
                }
            } message: {
                Text("Enter your display name")
            }
            .navigationDestination(for: ZenithProfileDestination.self) { destination in
                switch destination {
                case .account: AccountSettingsView()
                case .goals: FinancialGoalsView()
                case .security: SecurityPrivacyView()
                case .guide: ZenithGuideView()
                case .help: HelpSupportView()
                case .recurring: RecurringTransactionsListView()
                case .cloud: CloudSyncSettingsView()
                }
            }
        }
    }
}

// MARK: - Components

struct ZenithScoreCard: View {
    @State private var score: CGFloat = 0.0

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Zenith Score")
                    .font(.headline)
                    .foregroundColor(.gray)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("780")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("/ 850")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Text("Excellent")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.mintGreen)
                    .padding(.top, 4)
            }

            Spacer()

            // Circular Gauge
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: score)
                    .stroke(
                        AngularGradient(
                            colors: [Color.neonTurquoise, Color.mintGreen],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .neonTurquoise.opacity(0.5), radius: 8)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    score = 0.91  // 780/850 approx
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.zenithCharcoal.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct MenuRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.05))
                )

            Text(title)
                .font(.body)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .contentShape(Rectangle())  // Ensures the whole area is tappable
    }
}

// MARK: - Destination Views

struct ZenithBaseDetailView<Content: View>: View {
    var title: String
    var content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    content
                        .padding()
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AccountSettingsView: View {
    @AppStorage("userName") private var userName = "Zenith User"

    var body: some View {
        ZenithBaseDetailView(title: "Account Settings") {
            VStack(spacing: 20) {
                Text("Manage your account details and preferences.")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZenithSettingRow(label: "Username", value: userName)
                ZenithSettingRow(label: "Email", value: "user@zenith.app")
                ZenithSettingRow(label: "Phone", value: "Not set")

                Divider()
                    .background(Color.gray.opacity(0.3))

                // AI Status Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Configuration")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.neonTurquoise)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Zenith AI")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("Powered by Groq ✓")
                                .font(.caption)
                                .foregroundColor(.mintGreen)
                        }
                        Spacer()
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.mintGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.mintGreen.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct FinancialGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [FinancialGoal]

    @State private var showingAddEdit = false
    @State private var selectedGoal: FinancialGoal?

    var body: some View {
        ZenithBaseDetailView(title: "Financial Goals") {
            VStack(spacing: 20) {
                Text("Track and manage your financial targets.")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(goals) { goal in
                    Button(action: {
                        selectedGoal = goal
                    }) {
                        ZenithGoalCard(
                            title: goal.title,
                            current: goal.currentAmount,
                            target: goal.targetAmount,
                            color: Color.goalColors[goal.colorIndex % Color.goalColors.count]
                        )
                    }
                }

                Button(action: {
                    selectedGoal = nil  // New goal
                    showingAddEdit = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Goal")
                    }
                    .font(.headline)
                    .foregroundColor(.mintGreen)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.mintGreen.opacity(0.3), lineWidth: 1)
                            .searchable(text: .constant(""))  // Dummy to fix modifier chain if needed, removing for now
                    )
                }
            }
        }
        .sheet(item: $selectedGoal) { goal in
            AddEditGoalView(
                goal: goal,
                onSave: { updatedGoal in
                    // Changes are auto-tracked by SwiftData object reference
                    // Just ensuring we save context if needed, but not strictly required for updates
                    try? modelContext.save()
                },
                onDelete: { goalToDelete in
                    modelContext.delete(goalToDelete)
                })
        }
        .sheet(isPresented: $showingAddEdit) {
            AddEditGoalView(
                goal: nil,
                onSave: { newGoal in
                    modelContext.insert(newGoal)
                }, onDelete: { _ in })
        }
    }
}

struct AddEditGoalView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String
    @State private var current: String
    @State private var target: String
    @State private var monthlyContribution: String
    @State private var colorIndex: Int

    var goal: FinancialGoal?
    var onSave: (FinancialGoal) -> Void
    var onDelete: (FinancialGoal) -> Void

    init(
        goal: FinancialGoal?, onSave: @escaping (FinancialGoal) -> Void,
        onDelete: @escaping (FinancialGoal) -> Void
    ) {
        self.goal = goal
        self.onSave = onSave
        self.onDelete = onDelete

        _title = State(initialValue: goal?.title ?? "")
        _current = State(
            initialValue: goal != nil ? String(format: "%.0f", goal!.currentAmount) : "")
        _target = State(initialValue: goal != nil ? String(format: "%.0f", goal!.targetAmount) : "")
        _monthlyContribution = State(
            initialValue: goal != nil ? String(format: "%.0f", goal!.monthlyContribution) : "")
        _colorIndex = State(initialValue: goal?.colorIndex ?? 0)
    }

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack(spacing: 24) {
                Text(goal == nil ? "New Goal" : "Edit Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)

                VStack(spacing: 16) {
                    TextField("Goal Title (e.g. Vacation)", text: $title)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    TextField("Current Saved ($)", text: $current)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    TextField("Target Amount ($)", text: $target)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    TextField("Monthly Contribution ($)", text: $monthlyContribution)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    VStack(alignment: .leading) {
                        Text("Color Theme")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            ForEach(0..<Color.goalColors.count, id: \.self) { index in
                                Circle()
                                    .fill(Color.goalColors[index])
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                Color.white, lineWidth: colorIndex == index ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        colorIndex = index
                                    }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()

                Spacer()

                VStack(spacing: 16) {
                    Button(action: save) {
                        Text("Save Goal")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.mintGreen)
                            .cornerRadius(16)
                    }

                    if let goal = goal {
                        Button(action: {
                            onDelete(goal)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Delete Goal")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(16)
                        }
                    } else {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    private func save() {
        guard let currentAmount = Double(current),
            let targetAmount = Double(target),
            let monthly = Double(monthlyContribution),
            !title.isEmpty
        else { return }

        let id = goal?.id ?? UUID()
        let newGoal = FinancialGoal(
            id: id, title: title, currentAmount: currentAmount, targetAmount: targetAmount,
            monthlyContribution: monthly,
            colorIndex: colorIndex)
        onSave(newGoal)
        presentationMode.wrappedValue.dismiss()
    }
}

struct SecurityPrivacyView: View {
    @ObservedObject private var securityManager = SecurityManager.shared
    @State private var notificationsEnabled = false

    var body: some View {
        ZenithBaseDetailView(title: "Security & Privacy") {
            VStack(spacing: 20) {
                Toggle(
                    "Face ID / Touch ID",
                    isOn: Binding(
                        get: { securityManager.biometricsEnabled },
                        set: { newValue in
                            securityManager.biometricsEnabled = newValue
                            HapticManager.shared.medium()
                        }
                    )
                )
                .toggleStyle(SwitchToggleStyle(tint: .mintGreen))
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .foregroundColor(.white)

                Toggle("Push Notifications", isOn: $notificationsEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .mintGreen))
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .foregroundColor(.white)

                Button(action: {}) {
                    Text("Change Password")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                }
            }
        }
    }
}

struct HelpSupportView: View {
    @State private var showingFAQ = false
    @State private var showingContact = false

    var body: some View {
        ZenithBaseDetailView(title: "Help & Support") {
            VStack(spacing: 20) {
                Text("How can we help you today?")
                    .font(.headline)
                    .foregroundColor(.white)

                // FAQ Button
                Button(action: { showingFAQ = true }) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.mintGreen)
                        Text("FAQ")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }

                // Contact Support
                Button(action: { showingContact = true }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.neonTurquoise)
                        Text("Contact Support")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }

                // Rate App
                Button(action: {
                    if let url = URL(
                        string: "https://apps.apple.com/app/id123456789?action=write-review")
                    {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Rate App")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }

                // Terms of Service
                Button(action: {
                    if let url = URL(string: "https://example.com/terms") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.gray)
                        Text("Terms of Service")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }

                // Privacy Policy
                Button(action: {
                    if let url = URL(string: "https://example.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.gray)
                        Text("Privacy Policy")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }

                // App Version
                VStack(spacing: 4) {
                    Text("Zenith Finance")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Version 1.0.0")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .padding(.top, 20)
            }
        }
        .sheet(isPresented: $showingFAQ) {
            FAQView()
        }
        .sheet(isPresented: $showingContact) {
            ContactSupportView()
        }
    }
}

// MARK: - FAQ View
struct FAQView: View {
    @Environment(\.presentationMode) var presentationMode

    let faqs: [(question: String, answer: String)] = [
        (
            "How do I add a transaction?",
            "Tap the + button on the Dashboard, use voice input by tapping the microphone, or scan a receipt with the camera."
        ),
        (
            "Can I set budgets for categories?",
            "Yes! Go to the Planner tab to set monthly budgets for each spending category."
        ),
        (
            "Is my data secure?",
            "Absolutely. All data is stored locally on your device. We never send your financial data to external servers."
        ),
        (
            "How does the AI insight work?",
            "Our AI analyzes your spending patterns and provides personalized tips to help you save money."
        ),
        ("Can I export my data?", "Data export feature is coming soon in a future update."),
    ]

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("FAQ")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.6))
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(faqs, id: \.question) { faq in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(faq.question)
                                    .font(.headline)
                                    .foregroundColor(.mintGreen)
                                Text(faq.answer)
                                    .font(.body)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Contact Support View
struct ContactSupportView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var subject = ""
    @State private var message = ""
    @State private var showingSentAlert = false

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Contact Support")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.6))
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subject")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            TextField("Brief description", text: $subject)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            TextEditor(text: $message)
                                .frame(height: 150)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                        }

                        Button(action: {
                            // Simulate sending
                            HapticManager.shared.success()
                            showingSentAlert = true
                        }) {
                            Text("Send Message")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.mintGreen)
                                .cornerRadius(16)
                        }
                        .disabled(subject.isEmpty || message.isEmpty)
                        .opacity(subject.isEmpty || message.isEmpty ? 0.5 : 1)
                    }
                    .padding()
                }
            }
        }
        .alert("Message Sent!", isPresented: $showingSentAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Thank you for reaching out. We'll get back to you within 24 hours.")
        }
    }
}

struct ZenithGuideView: View {
    var body: some View {
        ZenithBaseDetailView(title: "App Guide") {
            VStack(spacing: 32) {
                // Header
                Text("How to use Zenith")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Voice Assistant Section
                GuideSection(
                    icon: "mic.fill",
                    title: "Voice Assistant",
                    description:
                        "Tap the microphone on the Dashboard to speak to Zenith AI. It serves as your personal financial brain.",
                    examples: [
                        "\"I spent $15 on lunch at Subway\"",
                        "\"How much did I save this month?\"",
                        "\"Add a recurring bill for Netflix\"",
                    ]
                )

                // Smart Scanner Section
                GuideSection(
                    icon: "doc.viewfinder",
                    title: "Smart Scanner",
                    description:
                        "Use the scanner to instantly digitize paper receipts. The AI automatically extracts the merchant, date, and total amount.",
                    examples: [
                        "Align the receipt within the frame",
                        "Ensure good lighting for best results",
                        "Review extracted data before saving",
                    ]
                )

                // Zenith Score Section
                GuideSection(
                    icon: "chart.bar.fill",
                    title: "Zenith Score",
                    description:
                        "Your financial health score (0-850). It improves as you save more, spend wisely, and hit your set financial goals.",
                    examples: []
                )

                Spacer(minLength: 20)
            }
        }
    }
}

struct GuideSection: View {
    let icon: String
    let title: String
    let description: String
    let examples: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.mintGreen)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.mintGreen)
            }

            Text(description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            if !examples.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Try saying:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .padding(.top, 4)

                    ForEach(examples, id: \.self) { example in
                        HStack(alignment: .top) {
                            Circle()
                                .fill(Color.mintGreen)
                                .frame(width: 4, height: 4)
                                .padding(.top, 6)
                            Text(example)
                                .font(.subheadline)
                                .italic()
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ZenithSettingRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ZenithGoalCard: View {
    var title: String
    var current: Double
    var target: Double
    var color: Color

    var progress: Double {
        return min(current / target, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .foregroundColor(color)
                    .fontWeight(.bold)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("$\(Int(current))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text("Goal: $\(Int(target))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

#Preview {
    ZenithProfileView()
}
