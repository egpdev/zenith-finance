//
//  ZenithSubscriptionView.swift
//  calculateAI
//
//  Premium Subscription View with StoreKit integration
//

import StoreKit
import SwiftUI

struct ZenithSubscriptionView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            ZenithBackground()

            VStack(spacing: 0) {
                // Header with Close button
                HStack {
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 30) {
                        // Premium Badge
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .mintGreen.opacity(0.3), .neonTurquoise.opacity(0.1),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.mintGreen)
                        }
                        .shadow(color: .mintGreen.opacity(0.3), radius: 20)

                        // Title Section
                        VStack(spacing: 12) {
                            Text("Zenith Premium")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Unlock the full power of your financial brain")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }

                        // Benefits List
                        VStack(alignment: .leading, spacing: 20) {
                            BenefitRow(
                                icon: "sparkles", title: "Advanced AI Insights",
                                description:
                                    "Deep analysis of your spending habits and personalized saving tips."
                            )
                            BenefitRow(
                                icon: "chart.bar.fill", title: "Unlimited Analytics",
                                description:
                                    "Access detailed historical data and future net worth projections."
                            )
                            BenefitRow(
                                icon: "doc.viewfinder", title: "Smart Receipt Scanning",
                                description:
                                    "Unlimited intelligent receipt scanning with auto-categorization."
                            )
                            BenefitRow(
                                icon: "cloud.fill", title: "Cloud Sync",
                                description: "Sync seamlessly across all your devices in real-time."
                            )
                            BenefitRow(
                                icon: "bell.badge.fill", title: "Smart Notifications",
                                description: "Get personalized alerts and weekly spending reports."
                            )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)

                        // Pricing Options
                        VStack(spacing: 16) {
                            Text("Choose your plan")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            if subscriptionManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .mintGreen))
                                    .padding()
                            } else if subscriptionManager.products.isEmpty {
                                // Fallback to static pricing if products not loaded
                                HStack(spacing: 15) {
                                    StaticPricingCard(
                                        title: "Monthly",
                                        price: "$4.99",
                                        period: "/mo",
                                        isSelected: selectedProduct == nil,
                                        isPopular: false
                                    ) {
                                        selectedProduct = nil
                                    }

                                    StaticPricingCard(
                                        title: "Yearly",
                                        price: "$49.99",
                                        period: "/yr",
                                        isSelected: true,
                                        isPopular: true,
                                        savings: "Save 20%"
                                    ) {}
                                }
                                .padding(.horizontal)
                            } else {
                                HStack(spacing: 15) {
                                    ForEach(subscriptionManager.products) { product in
                                        DynamicPricingCard(
                                            product: product,
                                            isSelected: selectedProduct?.id == product.id,
                                            isPopular: product.id.contains("yearly")
                                        ) {
                                            selectedProduct = product
                                            HapticManager.shared.light()
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        Spacer(minLength: 30)

                        // Subscribe Button
                        Button(action: {
                            Task {
                                await purchaseSubscription()
                            }
                        }) {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Subscribe Now")
                                }
                            }
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.mintGreen, Color.neonTurquoise],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .mintGreen.opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isPurchasing)
                        .padding(.horizontal)

                        // Restore Purchases
                        Button(action: {
                            Task {
                                await subscriptionManager.restorePurchases()
                                HapticManager.shared.success()
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundColor(.mintGreen)
                        }
                        .padding(.top, 8)

                        Text("Recurring billing, cancel anytime.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom)

                        // Legal links
                        HStack(spacing: 20) {
                            Button("Terms") {
                                if let url = URL(string: "https://example.com/terms") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.gray)

                            Button("Privacy") {
                                if let url = URL(string: "https://example.com/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                        .padding(.bottom)
                    }
                }
            }
        }
        .onAppear {
            // Select yearly by default if available
            if let yearly = subscriptionManager.products.first(where: { $0.id.contains("yearly") })
            {
                selectedProduct = yearly
            } else {
                selectedProduct = subscriptionManager.products.first
            }
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func purchaseSubscription() async {
        guard let product = selectedProduct ?? subscriptionManager.products.first else {
            // Demo mode - just dismiss
            HapticManager.shared.success()
            presentationMode.wrappedValue.dismiss()
            return
        }

        isPurchasing = true

        do {
            if (try await subscriptionManager.purchase(product)) != nil {
                HapticManager.shared.success()
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            HapticManager.shared.error()
        }

        isPurchasing = false
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.mintGreen)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.mintGreen.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Dynamic Pricing Card (StoreKit)
struct DynamicPricingCard: View {
    let product: Product
    let isSelected: Bool
    let isPopular: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if isPopular {
                    Text("MOST POPULAR")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.mintGreen)
                        .cornerRadius(8)
                        .padding(.top, -10)
                } else {
                    Text(" ")
                        .font(.system(size: 10))
                        .padding(.top, -10)
                }

                Text(product.id.contains("yearly") ? "Yearly" : "Monthly")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)

                Text(product.displayPrice)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(product.id.contains("yearly") ? "/yr" : "/mo")
                    .font(.caption)
                    .foregroundColor(.gray)

                if isPopular {
                    Text("Save 20%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.mintGreen)
                } else {
                    Text(" ")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? Color.mintGreen : Color.white.opacity(0.1),
                                lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - Static Pricing Card (Fallback)
struct StaticPricingCard: View {
    let title: String
    let price: String
    let period: String
    let isSelected: Bool
    let isPopular: Bool
    var savings: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if isPopular {
                    Text("MOST POPULAR")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.mintGreen)
                        .cornerRadius(8)
                        .padding(.top, -10)
                } else {
                    Text(" ")
                        .font(.system(size: 10))
                        .padding(.top, -10)
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(period)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                if let savings = savings {
                    Text(savings)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.mintGreen)
                } else {
                    Text(" ")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? Color.mintGreen : Color.white.opacity(0.1),
                                lineWidth: 2)
                    )
            )
        }
    }
}

#Preview {
    ZenithSubscriptionView()
}
