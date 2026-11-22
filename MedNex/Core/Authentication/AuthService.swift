//
//  AuthService.swift
//  MedNex
//

import Foundation
import LocalAuthentication

// MARK: - Auth Service Protocol
protocol AuthServiceProtocol: Sendable {
    func login(email: String, password: String) async throws -> MedNexUser
    func loginWithStaffId(staffId: String, password: String) async throws -> MedNexUser
    func register(email: String, password: String, name: String, role: UserRole) async throws -> MedNexUser
    func authenticateWithBiometrics() async throws -> Bool
    func logout() async
    func validatePassword(_ password: String) -> [String]
    
    // MARK: - OTP MFA
    func sendOTP(email: String) async throws
    func verifyOTP(email: String, code: String) async throws -> Bool
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case emailAlreadyInUse
    case weakPassword(reasons: [String])
    case biometricNotAvailable
    case biometricFailed
    case noSavedCredentials
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid email or password."
        case .userNotFound: return "No account found with these credentials."
        case .emailAlreadyInUse: return "This email is already registered."
        case .weakPassword(let reasons): return "Password too weak: \(reasons.joined(separator: ", "))"
        case .biometricNotAvailable: return "Biometric authentication is not available."
        case .biometricFailed: return "Biometric authentication failed."
        case .noSavedCredentials: return "Please sign in with email and password first to enable Face ID."
        case .networkError: return "Network error. Please check your connection."
        case .unknown(let msg): return msg
        }
    }
}

// MARK: - Mock Auth Service
final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    
    private let demoAccounts = MockDataService.demoAccounts
    
    func login(email: String, password: String) async throws -> MedNexUser {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(800))
        
        guard let account = demoAccounts.first(where: { $0.email.lowercased() == email.lowercased() && $0.password == password }) else {
            throw AuthError.invalidCredentials
        }
        
        return MedNexUser(
            email: account.email,
            role: account.role,
            displayName: account.displayName
        )
    }
    
    func loginWithStaffId(staffId: String, password: String) async throws -> MedNexUser {
        try await Task.sleep(for: .milliseconds(800))
        
        guard let account = demoAccounts.first(where: { $0.staffId == staffId && $0.password == password }) else {
            throw AuthError.invalidCredentials
        }
        
        return MedNexUser(
            email: account.email,
            role: account.role,
            displayName: account.displayName
        )
    }
    
    func register(email: String, password: String, name: String, role: UserRole) async throws -> MedNexUser {
        try await Task.sleep(for: .milliseconds(1000))
        
        let validationErrors = validatePassword(password)
        if !validationErrors.isEmpty {
            throw AuthError.weakPassword(reasons: validationErrors)
        }
        
        if demoAccounts.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            throw AuthError.emailAlreadyInUse
        }
        
        return MedNexUser(
            email: email,
            role: role,
            displayName: name
        )
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricNotAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock MedNex"
            ) { success, error in
                if success {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(throwing: AuthError.biometricFailed)
                }
            }
        }
    }
    
    func logout() async {
        try? await Task.sleep(for: .milliseconds(300))
    }
    
    func validatePassword(_ password: String) -> [String] {
        var errors: [String] = []
        if password.count < 8 { errors.append("At least 8 characters") }
        if !password.contains(where: { $0.isUppercase }) { errors.append("One uppercase letter") }
        if !password.contains(where: { $0.isNumber }) { errors.append("One number") }
        let specialChars = CharacterSet.punctuationCharacters.union(.symbols)
        if !password.unicodeScalars.contains(where: { specialChars.contains($0) }) {
            errors.append("One special character")
        }
        return errors
    }
    
    // MARK: - OTP MFA (Mock)
    
    func sendOTP(email: String) async throws {
        try await Task.sleep(for: .milliseconds(500))
        // Mock: OTP "sent" — accept 123456
    }
    
    func verifyOTP(email: String, code: String) async throws -> Bool {
        try await Task.sleep(for: .milliseconds(500))
        return code == "123456"
    }
}
