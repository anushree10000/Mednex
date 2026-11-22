//
//  DoctorPatientsView.swift
//  MedNex
//

import SwiftUI

struct DoctorPatientsView: View {
    @State private var searchText = ""
    @State private var showCallAlert = false
    @State private var callingPatient = ""
    @Environment(DataStore.self) private var dataStore
    
    /// Derive unique patients from appointments (group by patientId)
    private var patients: [(id: String, name: String, lastVisit: Date, condition: String)] {
        let grouped = Dictionary(grouping: dataStore.appointments, by: \.patientId)
        return grouped.compactMap { (patientId, appointments) in
            guard let latest = appointments.sorted(by: { $0.dateTime > $1.dateTime }).first else { return nil }
            let condition = latest.type.displayName
            return (id: patientId, name: latest.patientName, lastVisit: latest.dateTime, condition: condition)
        }
        .sorted { $0.lastVisit > $1.lastVisit }
    }
    
    var filteredPatients: [(id: String, name: String, lastVisit: Date, condition: String)] {
        if searchText.isEmpty { return patients }
        return patients.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.condition.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.md) {
                MedNexSearchBar(text: $searchText, placeholder: "Search patients...")
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                
                if filteredPatients.isEmpty {
                    EmptyStateView(icon: "person.2", title: "No Patients", message: "Patients from your appointments will appear here.")
                        .padding(.top, MedNexTheme.Spacing.xxl)
                } else {
                    LazyVStack(spacing: MedNexTheme.Spacing.sm) {
                        ForEach(filteredPatients, id: \.id) { patient in
                            GlassCard {
                                HStack(spacing: MedNexTheme.Spacing.md) {
                                    AvatarView(name: patient.name, size: 48, backgroundColor: MedNexTheme.Colors.patientTint)
                                    
                                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                                        Text(patient.name)
                                            .font(MedNexTheme.Typography.headline)
                                        
                                        HStack(spacing: MedNexTheme.Spacing.sm) {
                                            Label(patient.condition, systemImage: "cross.case")
                                        }
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                        
                                        Text("Last visit: \(patient.lastVisit.relative)")
                                            .font(MedNexTheme.Typography.caption2)
                                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(spacing: MedNexTheme.Spacing.xs) {
                                        NavigationLink {
                                            MedicalRecordEditorView()
                                        } label: {
                                            Image(systemName: "doc.text.fill")
                                                .foregroundStyle(MedNexTheme.Colors.primary)
                                        }
                                        
                                        Button {
                                            HapticManager.light()
                                            callingPatient = patient.name
                                            showCallAlert = true
                                        } label: {
                                            Image(systemName: "phone.fill")
                                                .foregroundStyle(MedNexTheme.Colors.success)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                    .padding(.bottom, MedNexTheme.Spacing.xxl)
                }
            }
        }
        .navigationTitle("My Patients")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .alert("Call \(callingPatient)?", isPresented: $showCallAlert) {
            Button("Call Now") {
                if let url = URL(string: "tel://+911234567890") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will open the phone dialer to call \(callingPatient).")
        }
    }
}
