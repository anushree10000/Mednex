//
//  NurseProfileView.swift
//  MedNex
//
//  Displays the nurse's profile and provides a sign-out method.
//  Styled to match AdminProfileSheet / DoctorProfileView design.

import SwiftUI

struct NurseProfileView: View {
    let appState: AppState
    @State private var showLogoutSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Profile Card
                VStack(spacing: MedNexTheme.Spacing.sm) {
                    #if canImport(PhotosUI) && canImport(UIKit)
                    EditableProfileAvatar(appState: appState, size: 80, backgroundColor: MedNexTheme.Colors.primary)
                        .padding(3)
                        .background(Circle().fill(Color.white))
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        .padding(.bottom, MedNexTheme.Spacing.sm)
                    #else
                    AvatarView(
                        name: appState.currentUser?.displayName ?? "Nurse",
                        imageURL: appState.currentUser?.profileImageURL,
                        size: 80,
                        backgroundColor: MedNexTheme.Colors.primary
                    )
                    .padding(3)
                    .background(Circle().fill(Color.white))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    .padding(.bottom, MedNexTheme.Spacing.sm)
                    #endif
                    
                    Text(appState.currentUser?.displayName ?? "Nurse")
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .foregroundStyle(Color(hex: "1C1C1E"))
                    
                    Text(appState.currentUser?.role.displayName ?? "Nurse")
                        .font(.system(size: 17, weight: .medium, design: .default))
                        .foregroundStyle(MedNexTheme.Colors.primary)
                    
                    if let email = appState.currentUser?.email, !email.isEmpty {
                        Text(email)
                            .font(.system(size: 15, weight: .regular, design: .default))
                            .foregroundStyle(Color(hex: "AEAEB2"))
                    }
                }
                .padding(MedNexTheme.Spacing.xl)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.top, MedNexTheme.Spacing.lg)
                
                // Sign Out
                Button {
                    HapticManager.warning()
                    showLogoutSheet = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(Color(hex: "FF3B30"))
                            .font(.system(size: 18, weight: .semibold))
                        Text("Sign Out")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(Color(hex: "1C1C1E"))
                        Spacer()
                    }
                    .padding()
                    .frame(minHeight: MedNexTheme.Layout.minTouchTarget)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
                    )
                }
                .buttonStyle(PremiumButtonStyle())
                .padding(.horizontal, MedNexTheme.Spacing.md)
                
                Text("MedNex v1.0 • Hospital Management System")
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Profile")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .alert("Sign Out?", isPresented: $showLogoutSheet) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                HapticManager.success()
                appState.logout()
            }
        } message: {
            Text("Are you sure you want to sign out? You can securely sign back in anytime.")
        }
    }
}

// MARK: - Premium Button Style
struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
