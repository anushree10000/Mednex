//
//  RegisterView.swift
//  MedNex
//
//  Native iOS register — with role selection and Face ID enrollment.

import SwiftUI

struct RegisterView: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    let isFirstTime: Bool
    let isStaffRegistration: Bool
    
    /// Roles available based on registration context
    private var availableRoles: [UserRole] {
        if isStaffRegistration {
            return [.doctor, .admin, .nurse, .labTechnician, .pharmacist]
        } else {
            return [.patient]
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MedNexTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: MedNexTheme.Spacing.xs) {
                        Text("Create Account")
                            .font(MedNexTheme.Typography.title)
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        Text(isFirstTime ? "Set up your MedNex account to get started" : "Join MedNex to manage your health")
                            .font(MedNexTheme.Typography.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    .padding(.top, MedNexTheme.Spacing.lg)
                    
                    // Form
                    GlassCard {
                        VStack(spacing: MedNexTheme.Spacing.md) {
                            // Full Name
                            fieldSection(title: "Full Name", icon: "person.fill") {
                                TextField("Enter your full name", text: $viewModel.fullName)
                                    .textContentType(.name)
                            }
                            
                            // Email
                            fieldSection(title: "Email", icon: "envelope.fill") {
                                TextField("Enter your email", text: $viewModel.email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                            
                            if !viewModel.email.isEmpty && !viewModel.isValidEmail {
                                Label("Please enter a valid email", systemImage: "exclamationmark.triangle.fill")
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundStyle(MedNexTheme.Colors.error)
                            }
                            
                            // Role Picker
                            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                                Text("Register as")
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                
                                if isStaffRegistration {
                                    // Staff: show dropdown with filtered roles
                                    HStack {
                                        Image(systemName: viewModel.selectedRole.icon)
                                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                        
                                        Picker("Role", selection: $viewModel.selectedRole) {
                                            ForEach(availableRoles) { role in
                                                Label(role.displayName, systemImage: role.icon)
                                                    .tag(role)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(MedNexTheme.Colors.textPrimary)
                                        
                                        Spacer()
                                    }
                                    .padding(MedNexTheme.Spacing.sm)
                                    .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                } else {
                                    // Patient: locked label, no dropdown
                                    HStack {
                                        Image(systemName: UserRole.patient.icon)
                                            .foregroundStyle(MedNexTheme.Colors.primary)
                                        Text(UserRole.patient.displayName)
                                            .font(MedNexTheme.Typography.body)
                                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(MedNexTheme.Colors.success)
                                    }
                                    .padding(MedNexTheme.Spacing.sm)
                                    .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                }
                            }
                            .onAppear {
                                // Ensure the selected role matches the registration context
                                if !availableRoles.contains(viewModel.selectedRole) {
                                    viewModel.selectedRole = availableRoles.first ?? .patient
                                }
                            }
                            
                            // Password
                            fieldSection(title: "Password", icon: "lock.fill") {
                                SecureField("Create a password", text: $viewModel.password)
                                    .textContentType(.newPassword)
                                    .onChange(of: viewModel.password) {
                                        viewModel.validatePasswordRealtime()
                                    }
                            }
                            
                            // Password requirements
                            if !viewModel.password.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    passwordRequirement("8+ characters", met: viewModel.password.count >= 8)
                                    passwordRequirement("One uppercase letter", met: viewModel.password.contains(where: { $0.isUppercase }))
                                    passwordRequirement("One number", met: viewModel.password.contains(where: { $0.isNumber }))
                                    passwordRequirement("One special character", met: viewModel.passwordValidationErrors.allSatisfy { !$0.contains("special") })
                                }
                            }
                            
                            // Confirm Password
                            fieldSection(title: "Confirm Password", icon: "lock.rotation") {
                                SecureField("Confirm password", text: $viewModel.confirmPassword)
                                    .textContentType(.password)
                            }
                            
                            if !viewModel.confirmPassword.isEmpty && !passwordsMatch {
                                Label("Passwords do not match", systemImage: "xmark.circle.fill")
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundStyle(MedNexTheme.Colors.error)
                            }
                            
                            // Register Button
                            Button {
                                Task { await viewModel.register() }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create Account")
                                }
                            }
                            .buttonStyle(.medNexPrimary)
                            .disabled(!viewModel.isRegisterValid || viewModel.isLoading)
                            .opacity(viewModel.isRegisterValid ? 1 : 0.6)
                            .padding(.top, MedNexTheme.Spacing.sm)
                        }
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                }
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
            .background(MedNexTheme.Colors.background)
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isFirstTime {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.showError = false }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .sheet(isPresented: $viewModel.showOTPVerification) {
                OTPVerificationView(viewModel: viewModel)
                    .interactiveDismissDisabled()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(MedNexTheme.Colors.background)
            }
            .sheet(isPresented: $viewModel.registrationComplete) {
                FaceIDEnrollmentView(viewModel: viewModel) {
                    dismiss()
                }
                .interactiveDismissDisabled()
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationBackground(MedNexTheme.Colors.background)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var passwordsMatch: Bool {
        viewModel.password == viewModel.confirmPassword
    }
    
    private func fieldSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
            Text(title)
                .font(MedNexTheme.Typography.caption)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                content()
            }
            .padding(MedNexTheme.Spacing.sm)
            .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
        }
    }
    
    private func passwordRequirement(_ text: String, met: Bool) -> some View {
        Label(text, systemImage: met ? "checkmark.circle.fill" : "circle")
            .font(MedNexTheme.Typography.caption)
            .foregroundStyle(met ? MedNexTheme.Colors.success : MedNexTheme.Colors.textTertiary)
    }
}

// MARK: - Face ID Enrollment View

struct FaceIDEnrollmentView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var isEnrolling = false
    @State private var enrollmentResult: Bool?
    var onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: MedNexTheme.Spacing.xl) {
            Spacer()
            
            // Face ID icon
            ZStack {
                Circle()
                    .fill(MedNexTheme.Colors.primary.opacity(0.12))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "faceid")
                    .font(.system(size: 56))
                    .foregroundStyle(MedNexTheme.Colors.primary)
                    .symbolEffect(.breathe, options: .repeating)
            }
            
            VStack(spacing: MedNexTheme.Spacing.sm) {
                Text("Enable Face ID")
                    .font(MedNexTheme.Typography.title2)
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                
                Text("Sign in quickly and securely with Face ID. You can change this in Settings anytime.")
                    .font(MedNexTheme.Typography.body)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MedNexTheme.Spacing.lg)
            }
            
            Spacer()
            
            VStack(spacing: MedNexTheme.Spacing.md) {
                // Enable Face ID
                Button {
                    Task {
                        isEnrolling = true
                        let success = await viewModel.enrollFaceID()
                        isEnrolling = false
                        enrollmentResult = success
                        
                        // Brief delay, then proceed
                        try? await Task.sleep(for: .milliseconds(400))
                        viewModel.completeRegistrationFlow()
                        onComplete()
                    }
                } label: {
                    if isEnrolling {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Enable Face ID")
                    }
                }
                .buttonStyle(.medNexPrimary)
                .disabled(isEnrolling)
                
                // Skip button
                Button {
                    HapticManager.light()
                    viewModel.completeRegistrationFlow()
                    onComplete()
                } label: {
                    Text("Not Now")
                        .font(MedNexTheme.Typography.headline)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
                .disabled(isEnrolling)
            }
            .padding(.horizontal, MedNexTheme.Spacing.lg)
            .padding(.bottom, MedNexTheme.Spacing.xxxl)
        }
    }
}
