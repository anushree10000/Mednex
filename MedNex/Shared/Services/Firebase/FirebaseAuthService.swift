//
//  FirebaseAuthService.swift
//  MedNex
//
//  Firebase Authentication implementation of AuthServiceProtocol.
//  Wrapped in #if canImport so the project compiles before packages resolve.

#if canImport(FirebaseAuth)
import Foundation
import FirebaseAuth
import LocalAuthentication

final class FirebaseAuthService: AuthServiceProtocol, @unchecked Sendable {
    
    private let log = LoggingService.shared
    private let keychain = KeychainService.shared
    
    // MARK: - Login with Email
    
    func login(email: String, password: String) async throws -> MedNexUser {
        log.auth("Attempting email login for: \(email)")
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Save credentials for biometric re-auth
            try? keychain.saveCredentials(email: email, password: password)
            
            // Fetch user profile from Supabase
            let user = try await fetchOrCreateUserProfile(
                firebaseUID: result.user.uid,
                email: email
            )
            
            log.auth("Login successful for: \(email), role: \(user.role.rawValue)")
            return user
            
        } catch let error as NSError {
            log.authError("Login failed", error: error)
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Login with Staff ID
    
    func loginWithStaffId(staffId: String, password: String) async throws -> MedNexUser {
        log.auth("Attempting staff login for ID: \(staffId)")
        
        do {
            let staffEmail = try await SupabaseService.shared.fetchStaffEmail(byStaffId: staffId)
            return try await login(email: staffEmail, password: password)
        } catch {
            log.authError("Staff ID login failed", error: error)
            throw AuthError.invalidCredentials
        }
    }
    
    // MARK: - Register
    
    func register(email: String, password: String, name: String, role: UserRole) async throws -> MedNexUser {
        log.auth("Attempting registration for: \(email), role: \(role.rawValue)")
        
        let validationErrors = validatePassword(password)
        if !validationErrors.isEmpty {
            throw AuthError.weakPassword(reasons: validationErrors)
        }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            let user = MedNexUser(
                id: result.user.uid,
                email: email,
                role: role,
                displayName: name
            )
            
            // Create Supabase profile (non-fatal — will retry on next login)
            do {
                try await SupabaseService.shared.createUserProfile(user)
                log.auth("Supabase profile created for: \(email)")
            } catch {
                log.warning("⚠️ Supabase profile creation failed (will retry on next login): \(error.localizedDescription)")
                print("⚠️ Supabase profile creation failed: \(error)")
            }
            
            try? keychain.saveCredentials(email: email, password: password)
            
            log.auth("Registration successful for: \(email)")
            return user
            
        } catch let error as NSError {
            log.authError("Registration failed", error: error)
            print("🔐❌ Firebase Registration Error Details:")
            print("   Code: \(error.code)")
            print("   Domain: \(error.domain)")
            print("   Description: \(error.localizedDescription)")
            print("   UserInfo: \(error.userInfo)")
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Biometrics
    
    func authenticateWithBiometrics() async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricNotAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Sign in to MedNex"
            )
            return success
        } catch {
            throw AuthError.biometricFailed
        }
    }
    
    func authenticateWithBiometricsAndLogin() async throws -> MedNexUser {
        // Pre-flight: ensure we have saved credentials before prompting Face ID
        guard keychain.hasCredentials() else {
            log.authError("No saved credentials — user must sign in with email first")
            throw AuthError.noSavedCredentials
        }
        
        let success = try await authenticateWithBiometrics()
        guard success else { throw AuthError.biometricFailed }
        
        do {
            let credentials = try keychain.retrieveCredentials()
            return try await login(email: credentials.email, password: credentials.password)
        } catch {
            log.authError("Biometric re-auth failed — credential retrieval error")
            throw AuthError.biometricFailed
        }
    }
    
    // MARK: - Logout
    
    func logout() async {
        do {
            try Auth.auth().signOut()
            log.auth("User signed out")
        } catch {
            log.authError("Sign out failed", error: error)
        }
    }
    
    // MARK: - Password Validation
    
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
    
    // MARK: - Session
    
    var currentFirebaseUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }
    
    func restoreSession() async -> MedNexUser? {
        guard let firebaseUser = currentFirebaseUser else {
            log.auth("No existing Firebase session")
            return nil
        }
        
        log.auth("Restoring session for: \(firebaseUser.email ?? "unknown")")
        
        do {
            let user = try await fetchOrCreateUserProfile(
                firebaseUID: firebaseUser.uid,
                email: firebaseUser.email ?? ""
            )
            return user
        } catch {
            log.authError("Session restore failed", error: error)
            return nil
        }
    }
    
    // MARK: - Helpers
    
    private func fetchOrCreateUserProfile(firebaseUID: String, email: String) async throws -> MedNexUser {
        if let existingUser = try? await SupabaseService.shared.fetchUserProfile(byId: firebaseUID) {
            return existingUser
        }
        
        log.warning("No Supabase profile found for \(firebaseUID), creating default")
        let user = MedNexUser(
            id: firebaseUID,
            email: email,
            role: .patient,
            displayName: email.components(separatedBy: "@").first ?? "User"
        )
        try? await SupabaseService.shared.createUserProfile(user)
        return user
    }
    
    private func mapFirebaseError(_ error: NSError) -> AuthError {
        guard error.domain == AuthErrorDomain else {
            return .unknown(error.localizedDescription)
        }
        
        switch AuthErrorCode(rawValue: error.code) {
        case .wrongPassword, .invalidCredential:
            return .invalidCredentials
        case .userNotFound:
            return .userNotFound
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword(reasons: ["Password is too weak"])
        case .networkError:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
    
    // MARK: - OTP MFA
    
    /// In-memory OTP store for on-device fallback when Edge Function isn't available
    private static var pendingOTPs: [String: (code: String, expiry: Date)] = [:]
    
    func sendOTP(email: String) async throws {
        // Generate a 6-digit code on-device
        let code = String(format: "%06d", Int.random(in: 0...999999))
        let expiry = Date().addingTimeInterval(5 * 60) // 5 minutes
        
        // Always store locally — this is the source of truth for verification
        Self.pendingOTPs[email.lowercased()] = (code: code, expiry: expiry)
        
        // Always print to console so the code is visible during development
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📧 MedNex OTP for \(email): \(code)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Best-effort: also try the Edge Function for real email delivery
        // This is fire-and-forget — doesn't affect the OTP flow if it fails
        Task.detached { [weak self] in
            do {
                let params: [String: Any] = ["email": email, "code": code, "action": "send"]
                print("📤 Calling OTP Edge Function for: \(email)")
                let response = try await self?.callOTPEdgeFunction(params: params)
                print("📬 Edge Function response: \(response ?? [:])")
                self?.log.auth("✅ OTP email sent via Edge Function to: \(email)")
            } catch {
                print("❌ Edge Function call failed: \(error)")
                self?.log.warning("⚠️ Edge Function email delivery failed: \(error.localizedDescription)")
            }
        }
    }
    
    func verifyOTP(email: String, code: String) async throws -> Bool {
        // Always verify against on-device stored code (source of truth)
        guard let stored = Self.pendingOTPs[email.lowercased()] else {
            return false
        }
        
        // Check expiry
        guard Date() < stored.expiry else {
            Self.pendingOTPs[email.lowercased()] = nil
            return false
        }
        
        let valid = stored.code == code
        if valid {
            Self.pendingOTPs[email.lowercased()] = nil // Consume the code
        }
        return valid
    }
    
    private func callOTPEdgeFunction(params: [String: Any]) async throws -> [String: Any] {
        let urlString = "\(EnvironmentConfig.supabaseURL)/functions/v1/otp-verify"
        guard let url = URL(string: urlString) else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8 // Don't wait forever
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(EnvironmentConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: params)
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        guard let resp = httpResponse as? HTTPURLResponse,
              (200...299).contains(resp.statusCode) else {
            let statusCode = (httpResponse as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "nil"
            print("❌ Edge Function HTTP \(statusCode): \(body)")
            throw AuthError.networkError
        }
        
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }
}
#endif
