//
//  AdminSettingsView.swift
//  MedNex
//

import SwiftUI

struct AdminSettingsView: View {
    let appState: AppState
    @State private var showLogoutAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Profile
                VStack(spacing: MedNexTheme.Spacing.sm) {
                    AvatarView(name: appState.currentUser?.displayName ?? "Admin", size: 80, backgroundColor: MedNexTheme.Colors.adminTint)
                    Text(appState.currentUser?.displayName ?? "Admin")
                        .font(MedNexTheme.Typography.title2)
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    Text(appState.currentUser?.role.displayName ?? "Administrator")
                        .font(MedNexTheme.Typography.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
                .padding(.top, MedNexTheme.Spacing.lg)
                
                // Settings
                GlassCard {
                    VStack(spacing: MedNexTheme.Spacing.sm) {
                        NavigationLink { SettingsDetailView(title: "Hospital Settings", icon: "building.2.fill", description: "Configure hospital name, address, operating hours, and general preferences.") } label: { settingRow("Hospital Settings", icon: "building.2.fill") }
                        Divider()
                        NavigationLink { SettingsDetailView(title: "User Management", icon: "person.badge.key.fill", description: "Manage user accounts, roles, permissions, and access controls for all staff.") } label: { settingRow("User Management", icon: "person.badge.key.fill") }
                        Divider()
                        NavigationLink { SettingsDetailView(title: "Notifications", icon: "bell.fill", description: "Configure notification preferences, alert thresholds, and communication channels.") } label: { settingRow("Notifications", icon: "bell.fill") }
                        Divider()
                        NavigationLink { SettingsDetailView(title: "Backup & Export", icon: "externaldrive.fill", description: "Schedule automatic backups, export patient data, and manage data retention policies.") } label: { settingRow("Backup & Export", icon: "externaldrive.fill") }
                        Divider()
                        NavigationLink { SettingsDetailView(title: "Security", icon: "lock.shield.fill", description: "Configure security policies, password requirements, session timeouts, and audit logging.") } label: { settingRow("Security", icon: "lock.shield.fill") }
                        Divider()
                        NavigationLink { SettingsDetailView(title: "About MedNex", icon: "info.circle.fill", description: "MedNex Hospital Management System v1.0\n\nBuilt for modern healthcare management.\n\n© 2024 MedNex Technologies") } label: { settingRow("About MedNex", icon: "info.circle.fill") }
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                
                // Logout
                Button {
                    HapticManager.warning()
                    showLogoutAlert = true
                } label: {
                    Text("Sign Out")
                        .font(MedNexTheme.Typography.headline)
                        .foregroundStyle(MedNexTheme.Colors.error)
                        .frame(maxWidth: .infinity, minHeight: MedNexTheme.Layout.minTouchTarget)
                }
                .glassCard()
                .padding(.horizontal, MedNexTheme.Spacing.md)
                
                Text("MedNex v1.0 • Hospital Management System")
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .alert("Sign Out?", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { appState.logout() }
        }
    }
    
    private func settingRow(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(MedNexTheme.Colors.primary)
                .frame(width: 28)
            Text(title).font(MedNexTheme.Typography.body)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(MedNexTheme.Colors.textTertiary)
        }
    }
}

// MARK: - Reusable Settings Detail View
struct SettingsDetailView: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                GlassCard {
                    VStack(spacing: MedNexTheme.Spacing.md) {
                        Image(systemName: icon)
                            .font(.system(size: 44))
                            .foregroundStyle(MedNexTheme.Colors.primary)
                            .padding(.top, MedNexTheme.Spacing.md)
                        
                        Text(description)
                            .font(MedNexTheme.Typography.body)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        StatusBadge(text: "Coming Soon", color: MedNexTheme.Colors.info, icon: "clock.fill")
                            .padding(.top, MedNexTheme.Spacing.sm)
                    }
                    .padding(MedNexTheme.Spacing.lg)
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
            }
            .padding(.top, MedNexTheme.Spacing.lg)
        }
        .navigationTitle(title)
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
    }
}
