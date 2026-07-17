//
//  PatientTabView.swift
//  MedNex
//

import SwiftUI

struct PatientTabView: View {
    let appState: AppState
    @State private var selectedTab = 0
    @State private var showProfile = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                NavigationStack {
                    PatientHomeView(appState: appState, showProfile: $showProfile, selectedTab: $selectedTab)
                }
            }
            
            Tab("Appointments", systemImage: "calendar", value: 1) {
                NavigationStack {
                    AppointmentListView(appState: appState)
                }
            }
            
            Tab("Health", systemImage: "heart.fill", value: 2) {
                NavigationStack {
                    HealthDashboardView()
                }
            }
            
            Tab("Billing", systemImage: "creditcard.fill", value: 3) {
                NavigationStack {
                    BillingView()
                }
            }
        }
        .tint(MedNexTheme.Colors.primary)
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                PatientProfileView(appState: appState)
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
