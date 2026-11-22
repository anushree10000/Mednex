//
//  DoctorProfileView.swift
//  MedNex
//

import SwiftUI

struct DoctorProfileView: View {
    let appState: AppState
    @State private var showLogoutAlert = false
    @Environment(DataStore.self) private var dataStore
    
    private var doctor: Doctor {
        // Try to find the logged-in doctor's record, or first available, or build a placeholder
        if let userId = appState.currentUser?.id,
           let match = dataStore.doctors.first(where: { $0.userId == userId }) {
            return match
        }
        if let first = dataStore.doctors.first {
            return first
        }
        // Fallback placeholder from logged-in user info
        return Doctor(
            name: appState.currentUser?.displayName ?? "Doctor",
            specialty: .generalMedicine
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Profile Header
                VStack(spacing: MedNexTheme.Spacing.sm) {
                    AvatarView(name: doctor.name, size: 80, backgroundColor: MedNexTheme.Colors.doctorTint)
                    
                    Text(doctor.name)
                        .font(MedNexTheme.Typography.title2)
                    
                    Text(doctor.specialty.rawValue)
                        .font(MedNexTheme.Typography.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.primary)
                    
                    HStack(spacing: MedNexTheme.Spacing.lg) {
                        VStack {
                            Text("\(doctor.experience)")
                                .font(MedNexTheme.Typography.title2)
                                .foregroundStyle(MedNexTheme.Colors.primary)
                            Text("Years Exp.")
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                        
                        Divider().frame(height: 40)
                        
                        VStack {
                            HStack(spacing: 2) {
                                Text(String(format: "%.1f", doctor.rating))
                                    .font(MedNexTheme.Typography.title2)
                                    .foregroundStyle(MedNexTheme.Colors.accent)
                                Image(systemName: "star.fill")
                                    .foregroundStyle(MedNexTheme.Colors.accent)
                            }
                            Text("\(doctor.totalRatings) Reviews")
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                        
                        Divider().frame(height: 40)
                        
                        VStack {
                            Text("₹\(Int(doctor.consultationFee))")
                                .font(MedNexTheme.Typography.title2)
                                .foregroundStyle(MedNexTheme.Colors.success)
                            Text("Fee")
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                    }
                    .padding(.top, MedNexTheme.Spacing.sm)
                }
                .padding(.top, MedNexTheme.Spacing.lg)
                
                // Info Cards
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        Label("About", systemImage: "info.circle.fill")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        Divider()
                        Text(doctor.bio)
                            .font(MedNexTheme.Typography.body)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        
                        HStack { Text("Education"); Spacer(); Text(doctor.education).foregroundStyle(MedNexTheme.Colors.textSecondary) }
                            .font(MedNexTheme.Typography.subheadline)
                        HStack { Text("License"); Spacer(); Text(doctor.licenseNumber).foregroundStyle(MedNexTheme.Colors.textSecondary) }
                            .font(MedNexTheme.Typography.subheadline)
                        HStack { Text("Languages"); Spacer(); Text(doctor.languages.joined(separator: ", ")).foregroundStyle(MedNexTheme.Colors.textSecondary) }
                            .font(MedNexTheme.Typography.subheadline)
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
                        .frame(maxWidth: .infinity)
                        .frame(height: MedNexTheme.Layout.minTouchTarget)
                        .background(
                            MedNexTheme.Colors.elevatedBackground,
                            in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md)
                        )
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
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
}
