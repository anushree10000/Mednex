//
//  OTPVerificationView.swift
//  MedNex
//
//  Compact 6-digit email OTP sheet shown after login/registration.
//  Verifies the one-time code before granting access.
//

import SwiftUI

struct OTPVerificationView: View {
    @Bindable var viewModel: AuthViewModel
    @FocusState private var isInputFocused: Bool
    @State private var animateContent = false
    
    var body: some View {
        VStack(spacing: MedNexTheme.Spacing.lg) {
            // Drag indicator area
            Spacer().frame(height: 4)
            
            // Header
            VStack(spacing: MedNexTheme.Spacing.sm) {
                Image(systemName: "envelope.badge.shield.half.filled.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(MedNexTheme.Colors.primary)
                    .symbolEffect(.breathe, options: .repeating)
                
                Text("Verify Your Email")
                    .font(MedNexTheme.Typography.title2)
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                
                Text("Enter the 6-digit code sent to\n**\(viewModel.maskedEmail)**")
                    .font(MedNexTheme.Typography.subheadline)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 15)
            
            // OTP Input
            otpDigitBoxes
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            
            // Verify Button
            Button {
                Task { await viewModel.verifyOTP() }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Verify & Continue")
                }
            }
            .buttonStyle(.medNexPrimary)
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .disabled(viewModel.otpCode.count < 6 || viewModel.isLoading)
            .opacity(viewModel.otpCode.count == 6 ? 1 : 0.6)
            .opacity(animateContent ? 1 : 0)
            
            // Resend
            resendSection
                .opacity(animateContent ? 1 : 0)
            
            Spacer()
        }
        .padding(.horizontal, MedNexTheme.Spacing.md)
        .scrollDismissesKeyboard(.interactively)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.showError = false }
        } message: {
            Text(viewModel.errorMessage ?? "Invalid code. Please try again.")
        }
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.1)) {
                animateContent = true
            }
            isInputFocused = true
        }
    }
    
    // MARK: - OTP Digit Boxes
    
    private var otpDigitBoxes: some View {
        HStack(spacing: MedNexTheme.Spacing.sm) {
            ForEach(0..<6, id: \.self) { index in
                let digit = index < viewModel.otpCode.count
                    ? String(viewModel.otpCode[viewModel.otpCode.index(viewModel.otpCode.startIndex, offsetBy: index)])
                    : ""
                
                Text(digit)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    .frame(width: 44, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md)
                            .fill(MedNexTheme.Colors.elevatedBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md)
                            .stroke(
                                index == viewModel.otpCode.count ? MedNexTheme.Colors.primary : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            }
        }
        .padding(.horizontal, MedNexTheme.Spacing.sm)
        .overlay(
            // Invisible TextField to capture input
            TextField("", text: Binding(
                get: { viewModel.otpCode },
                set: { newValue in
                    let filtered = String(newValue.filter(\.isNumber).prefix(6))
                    viewModel.otpCode = filtered
                }
            ))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($isInputFocused)
            .opacity(0.01) // Nearly invisible — captures input
            .frame(maxWidth: .infinity)
        )
    }
    
    // MARK: - Resend Section
    
    private var resendSection: some View {
        VStack(spacing: MedNexTheme.Spacing.xs) {
            if viewModel.otpResendCountdown > 0 {
                Text("Resend code in \(viewModel.otpResendCountdown)s")
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
            } else {
                Button {
                    Task { await viewModel.resendOTP() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Resend Code")
                    }
                    .font(MedNexTheme.Typography.subheadline.weight(.medium))
                    .foregroundStyle(MedNexTheme.Colors.primary)
                }
            }
        }
    }
}
