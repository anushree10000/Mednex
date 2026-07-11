//
//  OnboardingView.swift
//  MedNex
//
//  Dark theme onboarding — vibrant icons on black.

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    var onComplete: () -> Void
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "stethoscope",
            title: "Your Health, One Tap Away",
            description: "Book appointments, view medical records, and chat with an AI health assistant — all from your pocket.",
            gradient: [Color(hex: "30D158"), Color(hex: "34C759")]
        ),
        OnboardingPage(
            icon: "person.3.fill",
            title: "Built for Everyone",
            description: "Whether you're a patient seeking care or a healthcare professional managing patients — MedNex connects you all.",
            gradient: [Color(hex: "0A84FF"), Color(hex: "5E5CE6")]
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Private & Secure",
            description: "Face ID authentication, end-to-end encryption, and HIPAA-ready security protect your most sensitive health data.",
            gradient: [Color(hex: "BF5AF2"), Color(hex: "FF375F")]
        ),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(MedNexTheme.Animation.smooth, value: currentPage)
            
            // Bottom section
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Page indicators
                HStack(spacing: MedNexTheme.Spacing.xs) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? MedNexTheme.Colors.textPrimary : MedNexTheme.Colors.textPrimary.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(MedNexTheme.Animation.smooth, value: currentPage)
                    }
                }
                
                // CTA Button
                Button {
                    HapticManager.medium()
                    if currentPage < pages.count - 1 {
                        withAnimation(MedNexTheme.Animation.smooth) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.medNexPrimary)
                .padding(.horizontal, MedNexTheme.Spacing.xl)
                
                // Skip button
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        HapticManager.light()
                        onComplete()
                    }
                    .font(MedNexTheme.Typography.subheadline)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
            }
            .padding(.bottom, MedNexTheme.Spacing.xxxl)
        }
        .background(MedNexTheme.Colors.background)
    }
    
    @ViewBuilder
    private func onboardingPageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: MedNexTheme.Spacing.xxl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .opacity(0.15)
                    )
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(
                        LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .opacity(0.08)
                    )
                    .frame(width: 200, height: 200)
                
                Image(systemName: page.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .symbolEffect(.breathe, options: .repeating)
            }
            
            VStack(spacing: MedNexTheme.Spacing.sm) {
                Text(page.title)
                    .font(MedNexTheme.Typography.title)
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(MedNexTheme.Typography.body)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MedNexTheme.Spacing.xl)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Model
private struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
}
