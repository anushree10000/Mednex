//
//  RealtimeService.swift
//  MedNex
//
//  Live updates: listens for database changes through Supabase Realtime and
//  refreshes DataStore, so a prescription written by a doctor shows up on the
//  patient's and pharmacist's screens without a manual refresh.
//
//  Realtime applies the same row-level security policies as the REST API,
//  so each user only receives changes to rows they are allowed to see.
//

#if canImport(Supabase)
import Foundation
import Supabase

@MainActor
final class RealtimeService {
    static let shared = RealtimeService()

    private var channel: RealtimeChannelV2?
    private var listeners: [Task<Void, Never>] = []
    private var pendingRefresh: Task<Void, Never>?
    private let log = LoggingService.shared

    private init() {}

    /// Starts listening for the tables this role works with. Safe to call again:
    /// any previous subscription is stopped first.
    func start(userId: String, role: UserRole) async {
        await stop()
        guard EnvironmentConfig.isRealTimeEnabled else { return }

        let tables = Self.tables(for: role)
        let client = SupabaseService.shared.client
        let channel = client.channel("mednex-live-\(userId)")

        // Listeners must be registered before subscribing.
        for table in tables {
            let changes = channel.postgresChange(AnyAction.self, schema: "public", table: table)
            listeners.append(Task { [weak self] in
                for await _ in changes {
                    self?.scheduleRefresh(userId: userId, role: role, table: table)
                }
            })
        }

        do {
            try await channel.subscribeWithError()
            self.channel = channel
            log.data("📡 Live updates on: \(tables.joined(separator: ", "))")
        } catch {
            // The app still works without live updates; data loads at login as before.
            log.warning("⚠️ Live updates unavailable: \(error.localizedDescription)")
            listeners.forEach { $0.cancel() }
            listeners.removeAll()
            await client.removeChannel(channel)
        }
    }

    /// Stops listening. Called on logout.
    func stop() async {
        pendingRefresh?.cancel()
        pendingRefresh = nil
        listeners.forEach { $0.cancel() }
        listeners.removeAll()
        if let channel {
            await SupabaseService.shared.client.removeChannel(channel)
            self.channel = nil
        }
    }

    /// Changes often arrive in bursts (a prescription plus its medicines, a bill plus
    /// its items), so wait briefly and refresh once instead of once per row.
    private func scheduleRefresh(userId: String, role: UserRole, table: String) {
        log.data("🔔 Live change in \(table)")
        pendingRefresh?.cancel()
        pendingRefresh = Task {
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            await DataStore.shared.refreshFromSupabase(userId: userId, role: role)
        }
    }

    /// The tables each role's screens read from (mirrors DataStore.loadRoleData).
    static func tables(for role: UserRole) -> [String] {
        switch role {
        case .patient:
            return ["appointments", "prescriptions", "lab_tests", "vital_records", "bills", "notifications"]
        case .doctor:
            return ["appointments", "prescriptions", "lab_tests"]
        case .admin, .receptionist, .accountant:
            return ["staff", "departments", "inventory_items", "beds"]
        case .nurse:
            return ["notifications"]
        case .labTechnician:
            return ["lab_tests"]
        case .pharmacist:
            return ["prescriptions", "inventory_items"]
        }
    }
}
#endif
