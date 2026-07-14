//
//  DoctorTabView.swift
//  MedNex
//

import SwiftUI

struct DoctorTabView: View {
    let appState: AppState
    @State private var selectedTab = 0
    @State private var showProfile = false
    @State private var scheduleFilter = "Today"
    @Environment(DataStore.self) private var dataStore
    
    // Get latest user profile image from dataStore for reliable loading across all tabs
    private var currentUserProfileImageURL: String? {
        guard let userId = appState.currentUser?.id else { return appState.currentUser?.profileImageURL }
        let doctor = dataStore.doctors.first(where: { $0.id == userId })
        return doctor?.profileImageURL ?? appState.currentUser?.profileImageURL
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "rectangle.grid.2x2.fill", value: 0) {
                NavigationStack {
                    DoctorDashboardView(appState: appState, showProfile: $showProfile, selectedTab: $selectedTab, scheduleFilter: $scheduleFilter)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("Dashboard")
                                    .font(.system(.headline, weight: .semibold))
                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                            }
                            profileToolbarItem()
                        }
                }
            }
            
            Tab("Schedule", systemImage: "calendar.badge.clock", value: 1) {
                NavigationStack {
                    DoctorScheduleView(appState: appState, appointmentFilter: $scheduleFilter)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("Schedule")
                                    .font(.system(.headline, weight: .semibold))
                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                            }
                            profileToolbarItem()
                        }
                }
            }
            
            Tab("Patients", systemImage: "person.2.fill", value: 2) {
                NavigationStack {
                    DoctorPatientsView(appState: appState)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("Patients")
                                    .font(.system(.headline, weight: .semibold))
                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                            }
                            profileToolbarItem()
                        }
                }
            }
        }
        .tint(MedNexTheme.Colors.primary)
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                DoctorProfileView(appState: appState)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button { showProfile = false } label: {
                                Image(systemName: "xmark")
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                        }
                    }
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
                    name: appState.currentUser?.displayName ?? "D",
                    imageURL: currentUserProfileImageURL,
                    size: 32,
                    backgroundColor: MedNexTheme.Colors.doctorTint
                )
            }
        }
    }
}

// MARK: - Doctor More Menu
struct DoctorMoreView: View {
    let appState: AppState
    @State private var showCreateBill = false
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.md) {
                moreItem(icon: "doc.text.fill", title: "Write Prescription", subtitle: "Create prescriptions for patients", color: MedNexTheme.Colors.primary) {
                    PrescriptionWriterView(appState: appState)
                }
                
                moreItem(icon: "note.text", title: "Medical Records", subtitle: "Add notes & update patient records", color: MedNexTheme.Colors.info) {
                    MedicalRecordEditorView()
                }
                
                // Create Bill button (opens sheet)
                Button {
                    showCreateBill = true
                } label: {
                    DoctorCard(padding: MedNexTheme.Spacing.md) {
                        HStack(spacing: MedNexTheme.Spacing.md) {
                            Image(systemName: "indianrupeesign.circle.fill")
                                .font(.title2)
                                .foregroundStyle(MedNexTheme.Colors.success)
                                .frame(width: 44, height: 44)
                                .background(MedNexTheme.Colors.success.opacity(0.12), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Create Bill")
                                    .font(MedNexTheme.Typography.headline)
                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                Text("Generate a bill for a patient visit")
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        }
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .scrollContentBackground(.hidden)
        .doctorFlowBackground()
        .sheet(isPresented: $showCreateBill) {
            CreateBillSheet()
        }
    }
    
    private func moreItem<D: View>(icon: String, title: String, subtitle: String, color: Color, @ViewBuilder destination: @escaping () -> D) -> some View {
        NavigationLink {
            destination()
        } label: {
            DoctorCard(padding: MedNexTheme.Spacing.md) {
                HStack(spacing: MedNexTheme.Spacing.md) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                        .frame(width: 44, height: 44)
                        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        Text(subtitle)
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
            }
        }
    }
}
