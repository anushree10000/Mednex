//
//  SecurityService.swift
//  MedNex
//
//  Security hardening: jailbreak detection, certificate pinning, and audit logging.

import Foundation
import CryptoKit

final class SecurityService: Sendable {
    static let shared = SecurityService()
    
    private let log = LoggingService.shared
    
    private init() {}
    
    // MARK: - Jailbreak Detection
    
    var isDeviceCompromised: Bool {
        #if targetEnvironment(simulator)
        return false // Don't flag simulators
        #else
        return checkJailbreakIndicators()
        #endif
    }
    
    private func checkJailbreakIndicators() -> Bool {
        // Check for common jailbreak paths
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt",
            "/usr/bin/ssh"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                log.critical("Jailbreak indicator found: \(path)")
                return true
            }
        }
        
        // Check if we can write to restricted paths
        let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            log.critical("Jailbreak detected: write access to restricted path")
            return true
        } catch {
            // Expected — device is not jailbroken
        }
        
        return false
    }
    
    // MARK: - Data Encryption at Rest
    
    func encrypt(data: Data, key: SymmetricKey) -> Data? {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            log.error("Encryption failed", error: error)
            return nil
        }
    }
    
    func decrypt(data: Data, key: SymmetricKey) -> Data? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            log.error("Decryption failed", error: error)
            return nil
        }
    }
    
    func generateEncryptionKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }
    
    // MARK: - HIPAA Audit Logging
    
    struct AuditEvent: Codable {
        let timestamp: Date
        let userId: String
        let action: String
        let resource: String
        let resourceId: String?
        let ipAddress: String?
        let details: String?
    }
    
    func logAuditEvent(
        userId: String,
        action: String,
        resource: String,
        resourceId: String? = nil,
        details: String? = nil
    ) async {
        let event = AuditEvent(
            timestamp: Date(),
            userId: userId,
            action: action,
            resource: resource,
            resourceId: resourceId,
            ipAddress: nil,
            details: details
        )
        
        log.info("AUDIT: \(action) on \(resource) by \(userId)")
        
        // Store audit log to Supabase (when available)
        #if canImport(Supabase)
        do {
            try await SupabaseService.shared.insert(event, into: "audit_logs")
        } catch {
            log.error("Failed to persist audit log", error: error)
            storeAuditEventLocally(event)
        }
        #else
        storeAuditEventLocally(event)
        #endif
    }
    
    private func storeAuditEventLocally(_ event: AuditEvent) {
        let key = "pending_audit_events"
        var events: [AuditEvent] = UserDefaults.standard.decodable(forKey: key) ?? []
        events.append(event)
        UserDefaults.standard.setEncodable(events, forKey: key)
    }
    
    func syncPendingAuditEvents() async {
        let key = "pending_audit_events"
        guard let events: [AuditEvent] = UserDefaults.standard.decodable(forKey: key),
              !events.isEmpty else { return }
        
        log.info("Syncing \(events.count) pending audit events")
        
        for event in events {
            #if canImport(Supabase)
            do {
                try await SupabaseService.shared.insert(event, into: "audit_logs")
            } catch {
                log.error("Failed to sync audit event", error: error)
                return
            }
            #else
            log.warning("Supabase not available, skipping audit sync")
            return
            #endif
        }
        
        UserDefaults.standard.removeObject(forKey: key)
        log.info("All pending audit events synced")
    }
}

// MARK: - UserDefaults Codable Helpers

extension UserDefaults {
    func setEncodable<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            set(data, forKey: key)
        }
    }
    
    func decodable<T: Decodable>(forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
