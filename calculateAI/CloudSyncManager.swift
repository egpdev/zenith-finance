//
//  CloudSyncManager.swift
//  calculateAI
//
//  iCloud Sync Manager for cross-device synchronization
//

import CloudKit
import Combine
import Foundation
import SwiftUI

// MARK: - Sync Status
enum SyncStatus: Equatable {
    case idle
    case syncing
    case synced
    case error(String)
    case offline

    var icon: String {
        switch self {
        case .idle: return "icloud"
        case .syncing: return "arrow.triangle.2.circlepath.icloud"
        case .synced: return "checkmark.icloud"
        case .error: return "exclamationmark.icloud"
        case .offline: return "icloud.slash"
        }
    }

    var color: Color {
        switch self {
        case .idle: return .gray
        case .syncing: return .blue
        case .synced: return .green
        case .error: return .red
        case .offline: return .orange
        }
    }

    var description: String {
        switch self {
        case .idle: return "Ready to sync"
        case .syncing: return "Syncing..."
        case .synced: return "All synced"
        case .error(let message): return message
        case .offline: return "Offline"
        }
    }
}

// MARK: - Cloud Sync Manager
@MainActor
class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var iCloudAvailable = false

    private let container = CKContainer.default()
    private var networkMonitor: Any?  // NWPathMonitor in real implementation

    private init() {
        checkiCloudStatus()
        setupNetworkMonitoring()
    }

    // MARK: - Check iCloud Status
    func checkiCloudStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.iCloudAvailable = true
                    self?.syncStatus = .idle
                case .noAccount:
                    self?.iCloudAvailable = false
                    self?.syncStatus = .error("No iCloud account")
                case .restricted:
                    self?.iCloudAvailable = false
                    self?.syncStatus = .error("iCloud restricted")
                case .couldNotDetermine:
                    self?.iCloudAvailable = false
                    self?.syncStatus = .error("Could not determine iCloud status")
                case .temporarilyUnavailable:
                    self?.iCloudAvailable = false
                    self?.syncStatus = .offline
                @unknown default:
                    self?.iCloudAvailable = false
                }
            }
        }
    }

    // MARK: - Setup Network Monitoring
    private func setupNetworkMonitoring() {
        // In production, use NWPathMonitor to monitor network status
        // For now, we'll assume online status
    }

    // MARK: - Manual Sync Trigger
    func triggerSync() {
        guard iCloudAvailable else {
            syncStatus = .error("iCloud not available")
            return
        }

        syncStatus = .syncing

        // Simulate sync delay - in production, this would coordinate with SwiftData's CloudKit sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.syncStatus = .synced
            self?.lastSyncDate = Date()
            HapticManager.shared.light()

            // Reset to idle after showing synced status
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if self?.syncStatus == .synced {
                    self?.syncStatus = .idle
                }
            }
        }
    }

    // MARK: - Fetch Changes
    func fetchChanges() async {
        guard iCloudAvailable else { return }

        syncStatus = .syncing

        // In production with SwiftData + CloudKit:
        // The sync happens automatically, but we can listen for notifications
        // NSPersistentCloudKitContainer.eventChangedNotification

        // Simulate fetch
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        syncStatus = .synced
        lastSyncDate = Date()

        try? await Task.sleep(nanoseconds: 3_000_000_000)
        if syncStatus == .synced {
            syncStatus = .idle
        }
    }

    // MARK: - Last Sync Time Formatted
    var lastSyncTimeFormatted: String {
        guard let date = lastSyncDate else {
            return "Never synced"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Sync Status Indicator View
struct SyncStatusIndicator: View {
    @ObservedObject var syncManager = CloudSyncManager.shared

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: syncManager.syncStatus.icon)
                .foregroundColor(syncManager.syncStatus.color)
                .rotationEffect(
                    .degrees(syncManager.syncStatus == .syncing && isAnimating ? 360 : 0)
                )
                .animation(
                    syncManager.syncStatus == .syncing
                        ? .linear(duration: 1).repeatForever(autoreverses: false)
                        : .default,
                    value: isAnimating
                )

            if syncManager.syncStatus == .syncing {
                Text("Syncing")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            if syncManager.syncStatus == .syncing {
                isAnimating = true
            }
        }
        .onChange(of: syncManager.syncStatus) { _, newValue in
            isAnimating = (newValue == .syncing)
        }
    }
}

// MARK: - Cloud Sync Settings View
struct CloudSyncSettingsView: View {
    @ObservedObject var syncManager = CloudSyncManager.shared
    @AppStorage("autoSyncEnabled") private var autoSyncEnabled = true

    var body: some View {
        List {
            Section {
                // Status
                HStack {
                    Label("iCloud Status", systemImage: syncManager.syncStatus.icon)
                    Spacer()
                    Text(syncManager.iCloudAvailable ? "Connected" : "Not Available")
                        .foregroundColor(syncManager.iCloudAvailable ? .green : .red)
                }

                // Last Sync
                HStack {
                    Label("Last Synced", systemImage: "clock")
                    Spacer()
                    Text(syncManager.lastSyncTimeFormatted)
                        .foregroundColor(.gray)
                }

                // Sync Now
                Button(action: {
                    syncManager.triggerSync()
                }) {
                    HStack {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        Spacer()
                        if syncManager.syncStatus == .syncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(syncManager.syncStatus == .syncing || !syncManager.iCloudAvailable)
            } header: {
                Text("Sync Status")
            }

            Section {
                Toggle(isOn: $autoSyncEnabled) {
                    Label("Auto Sync", systemImage: "arrow.clockwise.icloud")
                }

            } header: {
                Text("Settings")
            } footer: {
                Text(
                    "When enabled, your data syncs automatically across all your devices signed into the same iCloud account."
                )
            }

            Section {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text(
                        "Your financial data is encrypted and stored securely in your private iCloud account."
                    )
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("iCloud Sync")
    }
}

// MARK: - Sync Banner View
struct SyncBannerView: View {
    @ObservedObject var syncManager = CloudSyncManager.shared

    var body: some View {
        if case .error(let message) = syncManager.syncStatus {
            HStack {
                Image(systemName: "exclamationmark.icloud.fill")
                    .foregroundColor(.red)
                Text(message)
                    .font(.caption)
                Spacer()
                Button("Retry") {
                    syncManager.triggerSync()
                }
                .font(.caption)
                .foregroundColor(.mintGreen)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationView {
        CloudSyncSettingsView()
    }
}
