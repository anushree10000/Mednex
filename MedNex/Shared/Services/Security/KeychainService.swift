//
//  KeychainService.swift
//  MedNex
//
//  Secure credential storage using iOS Keychain.

import Foundation
import Security

enum KeychainError: LocalizedError {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .duplicateEntry: return "Item already exists in keychain."
        case .unknown(let status): return "Keychain error: \(status)"
        case .itemNotFound: return "Item not found in keychain."
        case .encodingFailed: return "Failed to encode data."
        }
    }
}

final class KeychainService: Sendable {
    static let shared = KeychainService()
    
    private let serviceName = "com.mednex.app"
    
    private init() {}
    
    // MARK: - Save
    
    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    // MARK: - Retrieve
    
    func retrieve(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }
        
        return string
    }
    
    // MARK: - Delete
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Clear All
    
    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Convenience
    
    func saveCredentials(email: String, password: String) throws {
        try save(key: "user_email", value: email)
        try save(key: "user_password", value: password)
    }
    
    func retrieveCredentials() throws -> (email: String, password: String) {
        let email = try retrieve(key: "user_email")
        let password = try retrieve(key: "user_password")
        return (email, password)
    }
    
    func deleteCredentials() {
        delete(key: "user_email")
        delete(key: "user_password")
    }
    
    func hasCredentials() -> Bool {
        (try? retrieve(key: "user_email")) != nil
    }
    
    func saveUserToken(_ token: String) throws {
        try save(key: "firebase_token", value: token)
    }
    
    func retrieveUserToken() throws -> String {
        try retrieve(key: "firebase_token")
    }
}
