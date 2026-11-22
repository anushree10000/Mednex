//
//  AdminTabView.swift
//  MedNex
//

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
                }
            }
            
            Tab("Staff", systemImage: "person.3.fill", value: 1) {
                NavigationStack {
                    StaffManagementView()
                }
            }
            
            Tab("Reports", systemImage: "chart.line.uptrend.xyaxis", value: 2) {
                NavigationStack {
                    AdminReportsView()
                }
            }
            
            Tab("Billing", systemImage: "creditcard.fill", value: 3) {
                NavigationStack {
                    BillingOverviewView()
                }
            }
            
            Tab("More", systemImage: "ellipsis.circle.fill", value: 4) {
                NavigationStack {
                    AdminMoreView()
                }
            }
        }
        .tint(MedNexTheme.Colors.primary)
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                AdminSettingsView(appState: appState)
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

// MARK: - Admin More Menu
struct AdminMoreView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.md) {
                moreItem(icon: "building.2.fill", title: "Departments", subtitle: "Manage hospital departments", color: MedNexTheme.Colors.info) {
                    DepartmentManagementView()
                }
                
                moreItem(icon: "bed.double.fill", title: "Bed Management", subtitle: "Track bed allocation & availability", color: MedNexTheme.Colors.warning) {
                    BedManagementView()
                }
                
                moreItem(icon: "shippingbox.fill", title: "Inventory", subtitle: "Manage medical supply inventory", color: MedNexTheme.Colors.success) {
                    AdminInventoryView()
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("More")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
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
