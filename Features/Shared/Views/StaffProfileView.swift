//
//  StaffProfileView.swift
//  MedNex
//

import SwiftUI

struct StaffProfileView: View {
    let appState: AppState
    @State private var showLogoutAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                VStack(spacing: MedNexTheme.Spacing.sm) {
                    #if canImport(PhotosUI) && canImport(UIKit)
                    EditableProfileAvatar(appState: appState, size: 80, backgroundColor: MedNexTheme.Colors.primary)
                    #else
                    AvatarView(
                        name: appState.currentUser?.displayName ?? "Staff",
                        imageURL: appState.currentUser?.profileImageURL,
                        size: 80,
                        backgroundColor: MedNexTheme.Colors.primary
                    )
                    #endif
                    
                    Text(appState.currentUser?.displayName ?? "Staff")
                        .font(MedNexTheme.Typography.title2)
                    
                    Text(appState.currentUser?.role.displayName ?? "Staff")
                        .font(MedNexTheme.Typography.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.primary)
                    
                    Text(appState.currentUser?.email ?? "")
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
                .padding(.top, MedNexTheme.Spacing.lg)
                
                GlassCard {
                    VStack(spacing: MedNexTheme.Spacing.sm) {
                        NavigationLink { SettingsDetailView(title: "Shift Preferences", icon: "clock.fill", description: "View and manage your shift schedule, swap requests, and availability preferences.") } label: { settingRow("Shift Preferences", icon: "clock.fill") }
                        Divider()
                        NavigationLink { SettingsDetailView(title: "Notifications", icon: "bell.fill", description: "Configure alert preferences for patient updates, shift changes, and system notifications.") } label: { settingRow("Notifications", icon: "bell.fill") }
                        Divider()
                        NavigationLink { SettingsDetailView(title: "Appearance", icon: "paintbrush.fill", description: "Customize the app appearance, font size, and display preferences.") } label: { settingRow("Appearance", icon: "paintbrush.fill") }
                        Divider()
                        NavigationLink { SettingsDetailView(title: "Help & Support", icon: "questionmark.circle.fill", description: "Access help documentation, FAQs, and contact the IT support team.") } label: { settingRow("Help & Support", icon: "questionmark.circle.fill") }
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                
                // Sign Out — native iOS red button
                Button {
                    HapticManager.warning()
                    showLogoutAlert = true
                } label: {
                    Text("Sign Out")
                        .font(MedNexTheme.Typography.body)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, minHeight: MedNexTheme.Layout.minTouchTarget)
                        .background(
                            MedNexTheme.Colors.elevatedBackground,
                            in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md)
                        )
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                
                Text("MedNex v1.0")
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Profile")
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .alert("Sign Out?", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { appState.logout() }
        }
    }
    
    private func settingRow(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(MedNexTheme.Colors.primary).frame(width: 28)
            Text(title).font(MedNexTheme.Typography.body)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(MedNexTheme.Colors.textTertiary)
        }
    }
}
