//
//  AdminTabView.swift
//  MedNex

import SwiftUI

struct AdminTabView: View {
    let appState: AppState
    @State private var selectedTab = 0
    @State private var showProfile = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "chart.bar.fill", value: 0) {
                NavigationStack {
                    AdminDashboardView(appState: appState, showProfile: $showProfile)
                        .toolbar { profileToolbarItem() }
                }
            }
            
            Tab("Billing", systemImage: "creditcard.fill", value: 1) {
                NavigationStack {
                    BillingOverviewView()
                }
            }
            
            Tab("Staff", systemImage: "person.3.fill", value: 2) {
                NavigationStack {
                    StaffManagementView()
                }
            }
            
            Tab("Patients", systemImage: "person.2.fill", value: 3) {
                NavigationStack {
                    AdminPatientsView()
                }
            }
        }
        .tint(MedNexTheme.Colors.primary)
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                AdminProfileSheet(appState: appState)
            }
        }
    }
    
    @ToolbarContentBuilder
    private func profileToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                HapticManager.selection()
                showProfile = true
            } label: {
                AvatarView(
                    name: appState.currentUser?.displayName ?? "A",
                    imageURL: appState.currentUser?.profileImageURL,
                    size: 32,
                    backgroundColor: MedNexTheme.Colors.adminTint
                )
            }
            .accessibilityLabel("Profile")
        }
    }
}

// MARK: - Profile Sheet
// Simple, not over-designed. Just the essentials.
struct AdminProfileSheet: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutAlert = false
    
    var body: some View {
        List {
            Section {
                HStack(spacing: MedNexTheme.Spacing.md) {
                    #if canImport(PhotosUI) && canImport(UIKit)
                    EditableProfileAvatar(appState: appState, size: 64, backgroundColor: MedNexTheme.Colors.adminTint)
                    #else
                    AvatarView(
                        name: appState.currentUser?.displayName ?? "Admin",
                        imageURL: appState.currentUser?.profileImageURL,
                        size: 64,
                        backgroundColor: MedNexTheme.Colors.adminTint
                    )
                    #endif

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.currentUser?.displayName ?? "Admin")
                            .font(.headline)
                        Text(appState.currentUser?.role.displayName ?? "Administrator")
                            .font(.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, MedNexTheme.Spacing.xs)
                .listRowBackground(Color.clear)
            }
            
            Section("Account") {
                if let email = appState.currentUser?.email, !email.isEmpty {
                    HStack {
                        Text("Email")
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        Spacer()
                        Text(email)
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    }
                } else {
                    HStack {
                        Text("Email")
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        Spacer()
                        Text("Not available")
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                    }
                }
            }
            
            Section {
                Button("Sign Out", role: .destructive) {
                    HapticManager.warning()
                    showLogoutAlert = true
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .alert("Sign Out?", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { appState.logout() }
        }
    }
}
