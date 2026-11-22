//
//  ContentView.swift
//  MedNex
//

import SwiftUI

struct ContentView: View {
    @State var appState = AppState()
    @State private var authViewModel: AuthViewModel?
    @State private var showRegister = false
    @State private var showFirstTimeRegister = false
    @State private var isRestoringSession = false
    @Environment(DataStore.self) private var dataStore
    
    #if canImport(FirebaseAuth)
    private let authService: AuthServiceProtocol = FirebaseAuthService()
    #else
    private let authService: AuthServiceProtocol = MockAuthService()
    #endif
    private let networkMonitor = NetworkMonitor.shared
    
    
    var body: some View {
        Group {
            if !appState.isOnboardingComplete {
                OnboardingView {
                    appState.completeOnboarding()
                }
                .transition(.move(edge: .trailing))
            } else if appState.isAuthenticated, let role = appState.userRole {
                RoleRouter(role: role, appState: appState)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                ZStack {
                    MedNexTheme.Colors.background.ignoresSafeArea()
                    
                    VStack {
                        LoginView(viewModel: getAuthViewModel())
                        
                        // Show register link only for returning users
                        if appState.isRegistered {
                            Button {
                                showRegister = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Don't have an account?")
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    Text("Register")
                                        .foregroundStyle(MedNexTheme.Colors.primary)
                                }
                                .font(MedNexTheme.Typography.subheadline)
                            }
                            .padding(.bottom, MedNexTheme.Spacing.xl)
                        }
                    }
                }
                // Returning user register sheet
                .sheet(isPresented: $showRegister) {
                    RegisterView(viewModel: getAuthViewModel(), isFirstTime: false, isStaffRegistration: getAuthViewModel().isStaffLogin)
                }
                // First-time register sheet (optional — staff can dismiss and login instead)
                .sheet(isPresented: $showFirstTimeRegister) {
                    RegisterView(viewModel: getAuthViewModel(), isFirstTime: true, isStaffRegistration: getAuthViewModel().isStaffLogin)
                }
                .onAppear {
                    // Show register option for first-time users (dismissable)
                    if !appState.isRegistered {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showFirstTimeRegister = true
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(MedNexTheme.Animation.smooth, value: appState.isAuthenticated)
        .animation(MedNexTheme.Animation.smooth, value: appState.isOnboardingComplete)
        .onAppear {
            appState.loadOnboardingState()
            // Attempt to restore Firebase session on launch
            Task {
                await restoreSession()
            }
        }
        // Load backend data when user logs in
        .onChange(of: appState.isAuthenticated) { _, isAuth in
            if isAuth, let user = appState.currentUser {
                Task {
                    await dataStore.loadFromSupabase(userId: user.id, role: user.role)
                }
            }
        }
        // Offline banner
        .overlay(alignment: .top) {
            if !networkMonitor.isConnected {
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash")
                    Text("No internet connection")
                        .font(MedNexTheme.Typography.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.vertical, MedNexTheme.Spacing.xs)
                .background(Color.red.opacity(0.9), in: Capsule())
                .padding(.top, 1)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: networkMonitor.isConnected)
            }
        }
        .alert("Session Expired", isPresented: $appState.showSessionExpired) {
            Button("OK") { appState.showSessionExpired = false }
        } message: {
            Text("Your session has expired due to inactivity. Please sign in again.")
        }
    }
    
    private func getAuthViewModel() -> AuthViewModel {
        if let existing = authViewModel {
            return existing
        }
        let vm = AuthViewModel(authService: authService, appState: appState)
        authViewModel = vm
        return vm
    }
    
    private func restoreSession() async {
        guard appState.isOnboardingComplete, appState.isRegistered else { return }
        
        isRestoringSession = true
        #if canImport(FirebaseAuth)
        if let firebaseAuth = authService as? FirebaseAuthService,
           let user = await firebaseAuth.restoreSession() {
            print("🔄 Session restored for: \(user.email), role: \(user.role.rawValue), id: \(user.id)")
            await MainActor.run {
                appState.login(user: user)
            }
            // Explicitly load data — don't rely solely on onChange
            print("📡 Loading data from Supabase after session restore...")
            await dataStore.loadFromSupabase(userId: user.id, role: user.role)
            print("✅ Data load complete. Appointments: \(await dataStore.appointments.count)")
        }
        #endif
        isRestoringSession = false
    }
}

#Preview {
    ContentView()
}
