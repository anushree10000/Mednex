//
//  AdminPatientsView.swift
//  MedNex
//
//  Patients — filter-first design. The list is dense and scannable.
//  Count lives in the navigation title, not in stat cards.

import SwiftUI

struct AdminPatientsView: View {
    @State private var searchText = ""
    @State private var statusFilter: PatientStatusFilter = .all
    @Environment(DataStore.self) private var dataStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var filteredPatients: [Patient] {
        var list = dataStore.allPatients
        
        switch statusFilter {
        case .all: break
        case .admitted:
            let admittedIds = Set(dataStore.admissions.filter { $0.status == .admitted }.map { $0.patientId })
            list = list.filter { admittedIds.contains($0.id) }
        case .discharged:
            let admittedIds = Set(dataStore.admissions.filter { $0.status == .admitted }.map { $0.patientId })
            let dischargedIds = Set(dataStore.admissions.filter { $0.status == .discharged }.map { $0.patientId })
            list = list.filter { dischargedIds.contains($0.id) && !admittedIds.contains($0.id) }
        }
        
        if !searchText.isEmpty {
            list = list.filter { $0.personalInfo.fullName.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }
    
    private var admittedCount: Int { dataStore.admissions.filter { $0.status == .admitted }.count }
    private var maxListWidth: CGFloat { horizontalSizeClass == .regular ? 980 : .infinity }
    
    var body: some View {
        List {
            // Filter — the main tool on this screen
            Section {
                Picker("Status", selection: $statusFilter) {
                    Text("All (\(dataStore.allPatients.count))").tag(PatientStatusFilter.all)
                    Text("Admitted (\(admittedCount))").tag(PatientStatusFilter.admitted)
                    Text("Discharged").tag(PatientStatusFilter.discharged)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 1)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            
            // Patient list — dense, scannable rows
            if filteredPatients.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No patients" : "No results",
                    systemImage: "person.2.slash",
                    description: Text(searchText.isEmpty ? "No patients match this filter." : "Try a different search.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredPatients) { patient in
                    NavigationLink(value: patient) {
                        patientRow(patient)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .frame(maxWidth: maxListWidth)
        .frame(maxWidth: .infinity, alignment: .center)
        .navigationTitle("Patients")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search patients")
        .navigationDestination(for: Patient.self) { PatientDetailView(patient: $0) }
        .refreshable { await dataStore.refreshFromBackend() }
    }
    
    private func patientRow(_ patient: Patient) -> some View {
        let fullName = patient.personalInfo.fullName.isEmpty ? "Unknown" : patient.personalInfo.fullName
        let avatarName = patient.personalInfo.fullName.isEmpty ? "?" : patient.personalInfo.fullName
        let patientIdStr = "MNX-\(String(patient.id.prefix(6)).uppercased())"
        let age = patient.personalInfo.age
        let gender = patient.personalInfo.gender.displayName
        let bloodType = patient.medicalInfo.bloodType
        let isAdmitted = dataStore.admissions.contains(where: { $0.patientId == patient.id && $0.status == .admitted })
        let admission = dataStore.admissions.first(where: { $0.patientId == patient.id && $0.status == .admitted })
        
        return HStack(spacing: MedNexTheme.Spacing.sm) {
            AvatarView(
                name: avatarName,
                imageURL: patient.profileImageURL,
                size: 40,
                backgroundColor: MedNexTheme.Colors.patientTint
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(fullName)
                    .font(.body.weight(.medium))
                
                Text(patientIdStr)
                    .font(.caption2.monospaced())
                    .foregroundStyle(MedNexTheme.Colors.primary.opacity(0.7))
                
                patientMetadata(age: age, gender: gender, bloodType: bloodType)
            }
            
            Spacer()
            
            if statusFilter != .admitted, isAdmitted {
                Text("Admitted")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(MedNexTheme.Colors.info)
            }
            
            if statusFilter == .admitted, let admission = admission {
                admissionInfo(admission)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func patientMetadata(age: Int, gender: String, bloodType: BloodType) -> some View {
        HStack(spacing: 6) {
            if age > 0 { Text("\(age)y") }
            Text(gender)
            if bloodType != .unknown {
                Text(bloodType.rawValue)
                    .foregroundStyle(MedNexTheme.Colors.error)
            }
        }
        .font(.caption)
        .foregroundStyle(MedNexTheme.Colors.textTertiary)
    }
    
    private func admissionInfo(_ admission: Admission) -> some View {
        let days = Calendar.current.dateComponents([.day], from: admission.admissionDate, to: Date()).day ?? 0
        return VStack(alignment: .trailing, spacing: 2) {
            Text("Since \(admission.admissionDate.shortDate)")
                .font(.caption2)
                .foregroundStyle(MedNexTheme.Colors.info)
            Text("\(days)d")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
        }
    }
}

enum PatientStatusFilter: String, CaseIterable {
    case all, admitted, discharged
}
