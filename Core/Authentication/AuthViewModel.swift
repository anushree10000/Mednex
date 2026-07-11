//
//  AuthViewModel.swift
//  MedNex
//

import SwiftUI
import LocalAuthentication

@Observable
final class AuthViewModel {
    // MARK: - State
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var fullName: String = ""
    var staffId: String = ""
    var selectedRole: UserRole = .patient
    
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    var isStaffLogin: Bool = false
    var passwordValidationErrors: [String] = []
    var registrationComplete: Bool = false
    var registeredUser: MedNexUser?
    
    // MARK: - OTP MFA State
    var otpCode: String = ""
    var showOTPVerification: Bool = false
    var otpResendCountdown: Int = 0
    private var pendingMFAUser: MedNexUser?
    private var otpTimer: Timer?
    /// Tracks whether the OTP verification is for a new registration (true) or login (false)
    private var isRegistrationPending: Bool = false
    
    /// Masked email for display (e.g. "al***@gmail.com")
    var maskedEmail: String {
        let target = pendingMFAUser?.email ?? email
        guard let atIndex = target.firstIndex(of: "@") else { return target }
        let prefix = target[target.startIndex..<atIndex]
        if prefix.count <= 2 { return target }
        let visible = prefix.prefix(2)
        let domain = target[atIndex...]
        return "\(visible)***\(domain)"
    }
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let appState: AppState
    
    init(authService: AuthServiceProtocol, appState: AppState) {
        self.authService = authService
        self.appState = appState
    }
    
    // MARK: - Validation
    
    var isLoginValid: Bool {
        return !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }
    
    var isRegisterValid: Bool {
        return isValidEmail && !password.isEmpty && password == confirmPassword && !fullName.isEmpty && passwordValidationErrors.isEmpty
    }
    
    var isValidEmail: Bool {
        let emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
        return email.wholeMatch(of: emailRegex) != nil
    }
    
    func validatePasswordRealtime() {
        passwordValidationErrors = authService.validatePassword(password)
    }
    
    // MARK: - Actions
    
    func login() async {
        guard isLoginValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user: MedNexUser
            let trimmedInput = email.trimmingCharacters(in: .whitespaces)
            
            if isValidEmail {
                // Email login
                user = try await authService.login(email: trimmedInput, password: password)
            } else {
                // Staff ID login (e.g. DOC001, NRS001, ADMIN001)
                user = try await authService.loginWithStaffId(staffId: trimmedInput, password: password)
            }
            
            // Non-patient roles skip OTP — go directly to app
            if user.role != .patient {
                await MainActor.run {
                    HapticManager.success()
                    appState.login(user: user)
                }
            } else {
                // Patient login — require OTP
                await MainActor.run {
                    pendingMFAUser = user
                }
                try await authService.sendOTP(email: user.email)
                
                await MainActor.run {
                    HapticManager.success()
                    showOTPVerification = true
                    startResendCountdown()
                }
            }
        } catch {
            await MainActor.run {
                HapticManager.error()
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        
        isLoading = false
    }
    
    func register() async {
        guard isRegisterValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.register(
                email: email,
                password: password,
                name: fullName,
                role: selectedRole
            )
            
            // Hold user and send OTP for email verification
            await MainActor.run {
                pendingMFAUser = user
                isRegistrationPending = true
            }
            try await authService.sendOTP(email: user.email)
            
            await MainActor.run {
                HapticManager.success()
                showOTPVerification = true
                startResendCountdown()
            }
        } catch {
            await MainActor.run {
                HapticManager.error()
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        
        isLoading = false
    }
    
    func enrollFaceID() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Enable Face ID to sign in quickly and securely."
            )
            if success {
                await MainActor.run {
                    appState.setFaceIDEnabled(true)
                }
            }
            return success
        } catch {
            return false
        }
    }
    
    func completeRegistrationFlow() {
        appState.completeRegistration()
        if let user = pendingMFAUser ?? registeredUser {
            appState.login(user: user)
        }
        registrationComplete = false
        registeredUser = nil
        pendingMFAUser = nil
        isRegistrationPending = false
    }
    
    func authenticateWithBiometrics() async {
        do {
            #if canImport(FirebaseAuth)
            // Use Firebase biometric re-auth if available
            if let firebaseAuth = authService as? FirebaseAuthService {
                let user = try await firebaseAuth.authenticateWithBiometricsAndLogin()
                await MainActor.run {
                    HapticManager.success()
                    appState.login(user: user)
                }
            } else {
                try await fallbackBiometricAuth()
            }
            #else
            try await fallbackBiometricAuth()
            #endif
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func fallbackBiometricAuth() async throws {
        let success = try await authService.authenticateWithBiometrics()
        if success {
            let defaultUser = MedNexUser(
                email: "demo@mednex.com",
                role: .patient,
                displayName: "Alex Johnson"
            )
            await MainActor.run {
                HapticManager.success()
                appState.login(user: defaultUser)
            }
        }
    }
    
    func logout() async {
        await authService.logout()
        await MainActor.run {
            appState.logout()
            clearFields()
        }
    }
    
    func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        staffId = ""
        errorMessage = nil
        otpCode = ""
        showOTPVerification = false
        pendingMFAUser = nil
        isRegistrationPending = false
        otpTimer?.invalidate()
        otpTimer = nil
        otpResendCountdown = 0
    }
    
    // MARK: - OTP MFA Actions
    
    func verifyOTP() async {
        guard let user = pendingMFAUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let valid = try await authService.verifyOTP(email: user.email, code: otpCode)
            
            await MainActor.run {
                if valid {
                    HapticManager.success()
                    showOTPVerification = false
                    otpCode = ""
                    otpTimer?.invalidate()
                    
                    if isRegistrationPending {
                        // Registration flow: mark registered, complete flow
                        registeredUser = user
                        registrationComplete = true
                        pendingMFAUser = nil
                        isRegistrationPending = false
                    } else {
                        // Login flow: go directly to app
                        pendingMFAUser = nil
                        appState.login(user: user)
                    }
                } else {
                    HapticManager.error()
                    errorMessage = "Invalid code. Please check and try again."
                    showError = true
                    otpCode = ""
                }
            }
        } catch {
            await MainActor.run {
                HapticManager.error()
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        
        isLoading = false
    }
    
    func resendOTP() async {
        guard let user = pendingMFAUser else { return }
        
        do {
            try await authService.sendOTP(email: user.email)
            await MainActor.run {
                HapticManager.success()
                startResendCountdown()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to resend code. Try again."
                showError = true
            }
        }
    }
    
    private func startResendCountdown() {
        otpResendCountdown = 30
        otpTimer?.invalidate()
        otpTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            DispatchQueue.main.async {
                if self.otpResendCountdown > 0 {
                    self.otpResendCountdown -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}
