//
//  PatientProfileView.swift
//  MedNex
//

import SwiftUI

struct PatientProfileView: View {
    let appState: AppState
    @State private var showLogoutAlert = false
    @State private var showEditProfile = false
    @Environment(DataStore.self) private var dataStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Profile Header
                VStack(spacing: MedNexTheme.Spacing.sm) {
                    #if canImport(PhotosUI) && canImport(UIKit)
                    EditableProfileAvatar(appState: appState, size: 80, backgroundColor: MedNexTheme.Colors.patientTint)
                    #else
                    AvatarView(
                        name: appState.currentUser?.displayName ?? "User",
                        imageURL: appState.currentUser?.profileImageURL,
                        size: 80,
                        backgroundColor: MedNexTheme.Colors.patientTint
                    )
                    #endif
                    
                    Text(appState.currentUser?.displayName ?? "User")
                        .font(MedNexTheme.Typography.title2)
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    
                    Text(appState.currentUser?.email ?? "")
                        .font(MedNexTheme.Typography.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
                .padding(.top, MedNexTheme.Spacing.lg)
                
                // Personal Info
                sectionCard(title: "Personal Information", icon: "person.fill") {
                    infoRow("Full Name", value: dataStore.patient.personalInfo.fullName)
                    infoRow("Date of Birth", value: dataStore.patient.personalInfo.dateOfBirth.shortDate)
                    infoRow("Age", value: "\(dataStore.patient.personalInfo.age) years")
                    infoRow("Gender", value: dataStore.patient.personalInfo.gender.displayName)
                    infoRow("Phone", value: dataStore.patient.personalInfo.phone)
                    infoRow("Address", value: "\(dataStore.patient.personalInfo.address), \(dataStore.patient.personalInfo.city)")
                }
                
                // Medical Info
                sectionCard(title: "Medical Information", icon: "cross.case.fill") {
                    infoRow("Blood Type", value: dataStore.patient.medicalInfo.bloodType.rawValue)
                    infoRow("Allergies", value: dataStore.patient.medicalInfo.allergies.joined(separator: ", "))
                    infoRow("Conditions", value: dataStore.patient.medicalInfo.chronicConditions.joined(separator: ", "))
                    if let h = dataStore.patient.medicalInfo.height { infoRow("Height", value: "\(Int(h)) cm") }
                    if let w = dataStore.patient.medicalInfo.weight { infoRow("Weight", value: "\(Int(w)) kg") }
                }
                
                // Emergency Contact
                sectionCard(title: "Emergency Contact", icon: "phone.fill") {
                    if let contact = dataStore.patient.emergencyContacts.first {
                        infoRow("Name", value: contact.name)
                        infoRow("Relationship", value: contact.relationship)
                        infoRow("Phone", value: contact.phone)
                    }
                }
                
                // Settings
                sectionCard(title: "Settings", icon: "gearshape.fill") {
                    NavigationLink {
                        SettingsDetailView(title: "Notification Preferences", icon: "bell.fill", description: "Manage your notification settings for appointment reminders, lab results, prescription updates, and general health alerts.")
                    } label: {
                        settingsRow("Notification Preferences", icon: "bell.fill")
                    }
                    
                    NavigationLink {
                        SettingsDetailView(title: "Accessibility", icon: "accessibility", description: "Adjust text size, enable VoiceOver support, and configure other accessibility features to suit your needs.")
                    } label: {
                        settingsRow("Accessibility", icon: "accessibility")
                    }
                    
                    NavigationLink {
                        SettingsDetailView(title: "Privacy & Security", icon: "lock.fill", description: "Your health data is encrypted and stored securely. MedNex complies with HIPAA regulations to protect your medical information.\n\nYou can manage data sharing preferences, download your data, or request account deletion.")
                    } label: {
                        settingsRow("Privacy & Security", icon: "lock.fill")
                    }
                }
                
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
                
                Text("MedNex v1.0 • Your Health, Connected.")
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                    .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
        }
        .navigationTitle("Profile")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .alert("Sign Out?", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                appState.logout()
            }
        } message: {
            Text("Are you sure you want to sign out of MedNex?")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showEditProfile = true
                }
            }
        }
        .sheet(isPresented: $showEditProfile, onDismiss: {
            // Refresh patient data from Supabase after editing
            if let userId = appState.currentUser?.id {
                Task {
                    await dataStore.refreshPatientProfile(userId: userId)
                }
            }
        }) {
            EditPatientProfileView(patient: dataStore.patient)
        }
    }
    
    private func sectionCard(title: String, icon: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                Label(title, systemImage: icon)
                    .font(MedNexTheme.Typography.headline)
                    .foregroundStyle(MedNexTheme.Colors.primary)
                
                Divider()
                
                content()
            }
        }
        .padding(.horizontal, MedNexTheme.Spacing.md)
    }
    
    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(MedNexTheme.Typography.subheadline)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(MedNexTheme.Typography.subheadline.weight(.medium))
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private func settingsRow(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(MedNexTheme.Colors.primary)
                .frame(width: 28)
            Text(title)
                .font(MedNexTheme.Typography.body)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(MedNexTheme.Colors.textTertiary)
        }
    }
}
