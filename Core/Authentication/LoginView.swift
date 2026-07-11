//
//  LoginView.swift
//  MedNex
//
//  Native iOS login — Apple HIG compliant.

import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var animateContent = false
    @State private var showRegister = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: MedNexTheme.Spacing.xl) {
                    Spacer(minLength: 0)
                    
                    // Header
                    VStack(spacing: MedNexTheme.Spacing.sm) {
                        Image(systemName: "stethoscope")
                            .font(.system(size: 60))
                            .foregroundStyle(MedNexTheme.Colors.primary)
                            .symbolEffect(.breathe, options: .repeating)
                        
                        Text("MedNex")
                            .font(MedNexTheme.Typography.largeTitle)
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        
                        Text("Your Health, Connected.")
                            .font(MedNexTheme.Typography.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                // Form Fields — unified Email + Password
                VStack(spacing: MedNexTheme.Spacing.sm) {
                    HStack(spacing: MedNexTheme.Spacing.sm) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            .frame(width: 24)
                        TextField("Email or Staff ID", text: $viewModel.email, prompt: Text("Email or Staff ID").foregroundStyle(MedNexTheme.Colors.textTertiary))
                            .textContentType(.username)
                            .keyboardType(.default)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.lg)
                    .frame(height: 52)
                    .background(MedNexTheme.Colors.elevatedBackground, in: Capsule())
                    
                    // Password field
                    HStack(spacing: MedNexTheme.Spacing.sm) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            .frame(width: 24)
                        SecureField("Password", text: $viewModel.password, prompt: Text("Password").foregroundStyle(MedNexTheme.Colors.textTertiary))
                            .textContentType(.password)
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.lg)
                    .frame(height: 52)
                    .background(MedNexTheme.Colors.elevatedBackground, in: Capsule())
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                
                // Login Button
                Button {
                    Task { await viewModel.login() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                    }
                }
                .buttonStyle(.medNexPrimary)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .disabled(!viewModel.isLoginValid || viewModel.isLoading)
                .opacity(viewModel.isLoginValid ? 1 : 0.6)
                .opacity(animateContent ? 1 : 0)
                
                // Biometric Auth
                Button {
                    Task { await viewModel.authenticateWithBiometrics() }
                } label: {
                    HStack(spacing: MedNexTheme.Spacing.sm) {
                        Image(systemName: "faceid")
                            .font(.title2)
                        Text("Sign in with Face ID")
                            .font(MedNexTheme.Typography.headline)
                    }
                }
                .buttonStyle(.medNexSecondary)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .opacity(animateContent ? 1 : 0)
                
                // Register Button
                Button {
                    showRegister = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        Text("Register")
                            .foregroundStyle(MedNexTheme.Colors.primary)
                            .fontWeight(.semibold)
                    }
                    .font(MedNexTheme.Typography.subheadline)
                }
                .padding(.top, MedNexTheme.Spacing.sm)
                .opacity(animateContent ? 1 : 0)
                
                Spacer(minLength: 0)
            }
            .frame(minHeight: geometry.size.height)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
        }
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.showError = false }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred.")
        }
        .sheet(isPresented: $showRegister) {
            RegisterView(
                viewModel: viewModel,
                isFirstTime: false,
                isStaffRegistration: viewModel.isStaffLogin
            )
        }
        .sheet(isPresented: $viewModel.showOTPVerification) {
            OTPVerificationView(viewModel: viewModel)
                .interactiveDismissDisabled()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(MedNexTheme.Colors.background)
        }
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.1)) {
                animateContent = true
            }
        }
    }
}
