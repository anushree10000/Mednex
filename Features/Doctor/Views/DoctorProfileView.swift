//
//  DoctorProfileView.swift
//  MedNex
//

import SwiftUI

struct DoctorProfileView: View {
    let appState: AppState
    @State private var showLogoutAlert = false
    @Environment(DataStore.self) private var dataStore
    
    @State private var doctor: Doctor?
    @State private var isLoading = true
    
    /// Resolve a usable Doctor synchronously from DataStore.
    private func resolveLocalDoctor() -> Doctor {
        let userId = appState.currentUser?.id ?? ""
        if let match = dataStore.doctors.first(where: { $0.userId == userId }) {
            return match
        } else if let first = dataStore.doctors.first {
            return first
        }
        return Doctor(name: appState.currentUser?.displayName ?? "Doctor", specialty: .generalMedicine)
    }
    
    var body: some View {
        ScrollView {
            if let doctor {
                VStack(spacing: MedNexTheme.Spacing.lg) {
                    // Profile Header
                    VStack(spacing: MedNexTheme.Spacing.sm) {
#if canImport(PhotosUI) && canImport(UIKit)
                        EditableProfileAvatar(appState: appState, size: 80, backgroundColor: MedNexTheme.Colors.doctorTint)
#else
                        AvatarView(
                            name: doctor.name,
                            imageURL: appState.currentUser?.profileImageURL,
                            size: 80,
                            backgroundColor: MedNexTheme.Colors.doctorTint
                        )
#endif
                        
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
                    DoctorCard {
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
                    
                    // #19: Manage Availability
                    DoctorCard {
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                            Label("Manage Availability", systemImage: "clock.badge.checkmark.fill")
                                .font(MedNexTheme.Typography.headline)
                                .foregroundStyle(MedNexTheme.Colors.primary)
                            Divider()
                            
                            HStack {
                                Text("Available for Appointments")
                                    .font(MedNexTheme.Typography.subheadline)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { doctor.isAvailable },
                                    set: { newValue in
                                        self.doctor?.isAvailable = newValue
                                        dataStore.updateDoctorAvailability(
                                            doctorId: doctor.id,
                                            isAvailable: newValue
                                        )
                                    }
                                ))
                                .tint(MedNexTheme.Colors.success)
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Available Slots")
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    Text("\(doctor.availableSlots.count) slots configured")
                                        .font(MedNexTheme.Typography.subheadline.weight(.medium))
                                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Consultation Fee")
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    Text("₹\(Int(doctor.consultationFee))")
                                        .font(MedNexTheme.Typography.subheadline.weight(.medium))
                                        .foregroundStyle(MedNexTheme.Colors.success)
                                }
                            }
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
            } else if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading Profile...")
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                VStack {
                    Spacer()
                    Text("Could not load profile")
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            }
        }
        .onAppear {
            // Immediately populate from local DataStore to avoid empty state
            if doctor == nil {
                doctor = resolveLocalDoctor()
            }
        }
        .task {
            await fetchDoctorProfile()
        }
        .doctorFlowBackground()
        .alert("Sign Out?", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { appState.logout() }
        }
    }
    
    private func fetchDoctorProfile() async {
        guard let userId = appState.currentUser?.id else {
            isLoading = false
            return
        }
        
        // Capture fallback data on main actor before going async
        let localDoctor = resolveLocalDoctor()
        
        #if canImport(Supabase)
        do {
            let fetched = try await DoctorRepository.shared.fetchDoctor(byUserId: userId)
            self.doctor = fetched
            self.isLoading = false
        } catch {
            print("Failed to fetch doctor profile from Supabase: \(error)")
            self.doctor = localDoctor
            self.isLoading = false
        }
        #else
        self.doctor = localDoctor
        self.isLoading = false
        #endif
    }
}
