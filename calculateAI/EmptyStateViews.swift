//
//  EmptyStateViews.swift
//  calculateAI
//
//  Beautiful empty state views for various app sections
//

import SwiftUI

// MARK: - Generic Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            // Animated Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.mintGreen.opacity(0.1), Color.mintGreen.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Circle()
                    .stroke(Color.mintGreen.opacity(0.2), lineWidth: 1)
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.mintGreen, .mintGreen.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.mintGreen)
                    .cornerRadius(16)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - No Transactions Empty State
struct NoTransactionsEmptyState: View {
    var onAddTransaction: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "creditcard.fill",
            title: "No Transactions Yet",
            subtitle: "Start tracking your finances by adding your first transaction",
            actionTitle: "Add Transaction",
            action: onAddTransaction
        )
    }
}

// MARK: - No Goals Empty State
struct NoGoalsEmptyState: View {
    var onAddGoal: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "target",
            title: "No Financial Goals",
            subtitle: "Set savings goals to reach your financial dreams faster",
            actionTitle: "Create Goal",
            action: onAddGoal
        )
    }
}

// MARK: - No Categories Empty State
struct NoCategoriesEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "folder.fill",
            title: "No Categories",
            subtitle: "Categories help you organize and track your spending patterns"
        )
    }
}

// MARK: - No Search Results Empty State
struct NoSearchResultsEmptyState: View {
    let searchText: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))

            Text("No results for \"\(searchText)\"")
                .font(.headline)
                .foregroundColor(.white)

            Text("Try searching for a different term")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - No Recurring Transactions Empty State
struct NoRecurringEmptyState: View {
    var onAdd: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "arrow.triangle.2.circlepath.circle.fill",
            title: "No Recurring Transactions",
            subtitle:
                "Track subscriptions, bills, and regular payments so you never miss a due date",
            actionTitle: "Add Recurring",
            action: onAdd
        )
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let title: String
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if let retry = retryAction {
                Button(action: retry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.mintGreen)
                    .cornerRadius(12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading State View
struct LoadingStateView: View {
    let message: String

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.mintGreen.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.mintGreen, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }
            .onAppear { isAnimating = true }

            Text(message)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Celebration View (for goal completion)
struct CelebrationView: View {
    let title: String
    let subtitle: String
    var onDismiss: () -> Void

    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(showConfetti ? 1 : 0.5)
                        .animation(.spring(response: 0.6), value: showConfetti)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.headline)
                        .foregroundColor(.gray)
                }

                Button(action: onDismiss) {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Color.mintGreen)
                        .cornerRadius(16)
                }
                .padding(.top)
            }
        }
        .onAppear {
            showConfetti = true
            HapticManager.shared.success()
        }
    }
}

// MARK: - Premium Feature Locked View
struct PremiumFeatureLockedView: View {
    let featureName: String
    var onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Premium Feature")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("\(featureName) is available with Zenith Premium")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            Button(action: onUnlock) {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Upgrade to Premium")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
        }
        .padding(40)
        .background(Color.zenithCharcoal)
        .cornerRadius(24)
    }
}

#Preview {
    ZStack {
        Color.zenithBlack.ignoresSafeArea()
        NoTransactionsEmptyState(onAddTransaction: {})
    }
}
