//
//  DoctorTabView.swift
//  MedNex
//

import SwiftUI

struct DoctorTabView: View {
    let appState: AppState
    @State private var selectedTab = 0
    @State private var showProfile = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "rectangle.grid.2x2.fill", value: 0) {
                NavigationStack {
                    DoctorDashboardView(appState: appState, showProfile: $showProfile)
                }
            }
            
            Tab("Schedule", systemImage: "calendar.badge.clock", value: 1) {
                NavigationStack {
                    DoctorScheduleView()
                }
            }
            
            Tab("Patients", systemImage: "person.2.fill", value: 2) {
                NavigationStack {
                    DoctorPatientsView()
                }
            }
            
            Tab("Lab Orders", systemImage: "flask.fill", value: 3) {
                NavigationStack {
                    DoctorLabOrderView(appState: appState)
                }
            }
            
            Tab("More", systemImage: "ellipsis.circle.fill", value: 4) {
                NavigationStack {
                    DoctorMoreView(appState: appState)
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
                    GlassCard(padding: MedNexTheme.Spacing.md) {
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
        .navigationTitle("More")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .sheet(isPresented: $showCreateBill) {
            CreateBillSheet()
        }
    }
    
    private func moreItem<D: View>(icon: String, title: String, subtitle: String, color: Color, @ViewBuilder destination: @escaping () -> D) -> some View {
        NavigationLink {
            destination()
        } label: {
            GlassCard(padding: MedNexTheme.Spacing.md) {
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
