//
//  PatientSettingsViews.swift
//  MedNex
//
//  Settings sub-views for Patient Profile — Apple HIG compliant.
//  Uses @AppStorage for persistence; swap with backend UserDefaults/API later.

import SwiftUI

// MARK: - Notification Preferences

struct NotificationPreferencesView: View {
    @AppStorage("notif_appointments") private var appointmentReminders = true
    @AppStorage("notif_labResults") private var labResults = true
    @AppStorage("notif_prescriptions") private var prescriptions = true
    @AppStorage("notif_billing") private var billing = true
    @AppStorage("notif_promotions") private var promotions = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Appointment Reminders", isOn: $appointmentReminders)
                Toggle("Lab Results", isOn: $labResults)
                Toggle("Prescriptions", isOn: $prescriptions)
                Toggle("Billing & Payments", isOn: $billing)
            } header: {
                Text("Alerts")
            } footer: {
                Text("Receive push notifications for important updates about your health and appointments.")
            }
            
            Section {
                Toggle("Health Tips & Promotions", isOn: $promotions)
            } header: {
                Text("Optional")
            } footer: {
                Text("Occasional tips and offers from MedNex. You can turn this off anytime.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Accessibility Settings

struct AccessibilitySettingsView: View {
    @AppStorage("accessibility_largerText") private var largerText = false
    @AppStorage("accessibility_highContrast") private var highContrast = false
    @AppStorage("accessibility_reduceMotion") private var reduceMotion = false
    @AppStorage("accessibility_haptics") private var haptics = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Larger Text", isOn: $largerText)
                Toggle("Increase Contrast", isOn: $highContrast)
                Toggle("Reduce Motion", isOn: $reduceMotion)
            } header: {
                Text("Display")
            } footer: {
                Text("These settings complement your system accessibility preferences.")
            }
            
            Section {
                Toggle("Haptic Feedback", isOn: $haptics)
            } header: {
                Text("Interaction")
            } footer: {
                Text("Feel subtle vibrations when tapping buttons and performing actions.")
            }
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy & Security

struct PrivacySecurityView: View {
    @AppStorage("privacy_faceId") private var faceIdEnabled = false
    @AppStorage("privacy_dataSharing") private var dataSharing = true
    @AppStorage("privacy_analytics") private var analytics = true
    @State private var showChangePassword = false
    @State private var showDeleteAccount = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Face ID / Touch ID", isOn: $faceIdEnabled)
            } header: {
                Text("Authentication")
            } footer: {
                Text("Use biometrics to quickly and securely sign in to MedNex.")
            }
            
            Section {
                Button {
                    showChangePassword = true
                } label: {
                    HStack {
                        Text("Change Password")
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                    }
                }
            } header: {
                Text("Account")
            }
            
            Section {
                Toggle("Share Health Data with Doctors", isOn: $dataSharing)
                Toggle("Usage Analytics", isOn: $analytics)
            } header: {
                Text("Data")
            } footer: {
                Text("Help us improve MedNex by sharing anonymous usage data. Your medical data is never shared without your explicit consent.")
            }
            
            Section {
                Button(role: .destructive) {
                    showDeleteAccount = true
                } label: {
                    Text("Delete Account")
                }
            } footer: {
                Text("Permanently delete your account and all associated data. This action cannot be undone.")
            }
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Change Password", isPresented: $showChangePassword) {
            Button("Cancel", role: .cancel) {}
            Button("OK") {}
        } message: {
            Text("A password reset link will be sent to your registered email address.")
        }
        .alert("Delete Account?", isPresented: $showDeleteAccount) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {}
        } message: {
            Text("This will permanently delete your account, medical records, and all associated data. This action cannot be undone.")
        }
    }
}
