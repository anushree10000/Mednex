//
//  AppState.swift
//  MedNex
//

import SwiftUI

@Observable
final class AppState {
    var currentUser: MedNexUser?
    var isAuthenticated: Bool = false
    var isOnboardingComplete: Bool = false
    var isRegistered: Bool = false
    var isFaceIDEnabled: Bool = false
    var isLoading: Bool = false
    var showSessionExpired: Bool = false
    
    // Session management
    private var lastActivityDate: Date = Date()
    private var sessionTimeoutInterval: TimeInterval {
        TimeInterval(EnvironmentConfig.sessionTimeoutMinutes * 60)
    }
    
    var userRole: UserRole? {
        currentUser?.role
    }
    
    var isPatient: Bool {
        userRole == .patient
    }
    
    var isDoctor: Bool {
        userRole == .doctor
    }
    
    var isAdmin: Bool {
        userRole == .admin
    }
    
    // MARK: - Session Management
    
    func recordActivity() {
        lastActivityDate = Date()
    }
    
    func checkSessionTimeout() -> Bool {
        guard isAuthenticated else { return false }
        let elapsed = Date().timeIntervalSince(lastActivityDate)
        if elapsed > sessionTimeoutInterval {
            logout()
            showSessionExpired = true
            return true
        }
        return false
    }
    
    // MARK: - Auth Actions
    
    func login(user: MedNexUser) {
        withAnimation(MedNexTheme.Animation.smooth) {
            currentUser = user
            isAuthenticated = true
            lastActivityDate = Date()
        }
    }
    
    func logout() {
        withAnimation(MedNexTheme.Animation.smooth) {
            currentUser = nil
            isAuthenticated = false
        }
        // Don't clear keychain credentials — they're needed for Face ID re-login
    }
    
    func completeOnboarding() {
        withAnimation(MedNexTheme.Animation.smooth) {
            isOnboardingComplete = true
            UserDefaults.standard.set(true, forKey: "onboarding_complete")
        }
    }
    
    func loadOnboardingState() {
        isRegistered = UserDefaults.standard.bool(forKey: "user_registered")
        isFaceIDEnabled = UserDefaults.standard.bool(forKey: "faceid_enabled")
        
        // If user hasn't registered, treat as fresh install
        // (handles stale UserDefaults from previous builds)
        if !isRegistered {
            isOnboardingComplete = false
            UserDefaults.standard.removeObject(forKey: "onboarding_complete")
        } else {
            isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboarding_complete")
        }
    }
    
    func completeRegistration() {
        withAnimation(MedNexTheme.Animation.smooth) {
            isRegistered = true
            UserDefaults.standard.set(true, forKey: "user_registered")
        }
    }
    
    func setFaceIDEnabled(_ enabled: Bool) {
        isFaceIDEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "faceid_enabled")
    }
}
