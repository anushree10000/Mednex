//
//  AdminAdmitPatientSheet.swift
//  MedNex
//
//  Calm, vertical form. No visual noise — just clear inputs.

import SwiftUI

struct AdminAdmitPatientSheet: View {
    let patient: Patient
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    
    @State private var bedNumber = ""
    @State private var wardNumber = ""
    @State private var diagnosis = ""
    @State private var dailyRoomRate = ""
    @State private var selectedDoctorIds: Set<String> = []
    @State private var selectedNurseId = ""
    @State private var showSuccess = false
    
    private var nurses: [Staff] { dataStore.staff.filter { $0.role == .nurse && $0.isActive } }
    
    private var isValid: Bool {
        !bedNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        !wardNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedDoctorIds.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Patient summary — read-only context
                Section {
                    HStack(spacing: MedNexTheme.Spacing.sm) {
                        AvatarView(
                            name: patient.personalInfo.fullName.isEmpty ? "?" : patient.personalInfo.fullName,
                            imageURL: patient.profileImageURL,
                            size: 40,
                            backgroundColor: MedNexTheme.Colors.patientTint
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(patient.personalInfo.fullName.isEmpty ? "Unknown" : patient.personalInfo.fullName)
                                .font(.body.weight(.medium))
                            if patient.personalInfo.age > 0 {
                                Text("\(patient.personalInfo.age) yrs · \(patient.personalInfo.gender.displayName)")
                                    .font(.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                        }
                    }
                }
                
                // Location
                Section("Location") {
                    TextField("Ward (e.g. GEN-1)", text: $wardNumber)
                    TextField("Bed (e.g. B-12)", text: $bedNumber)
                }
                
                // Doctors
                Section("Doctors") {
                    ForEach(dataStore.doctors) { doctor in
                        Button {
                            if selectedDoctorIds.contains(doctor.id) {
                                selectedDoctorIds.remove(doctor.id)
                            } else {
                                selectedDoctorIds.insert(doctor.id)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(doctor.name)
                                        .font(.body)
                                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                    Text(doctor.specialty.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                }
                                Spacer()
                                Image(systemName: selectedDoctorIds.contains(doctor.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedDoctorIds.contains(doctor.id) ? MedNexTheme.Colors.primary : MedNexTheme.Colors.textTertiary)
                            }
                        }
                    }
                }
                
                // Nurse
                Section("Nurse") {
                    Picker("Assign nurse", selection: $selectedNurseId) {
                        Text("None").tag("")
                        ForEach(nurses) { nurse in
                            Text(nurse.name).tag(nurse.id)
                        }
                    }
                }
                
                // Diagnosis + rate
                Section("Clinical") {
                    TextField("Diagnosis", text: $diagnosis, axis: .vertical)
                        .lineLimit(2...4)
                    
                    HStack {
                        Text("₹")
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        TextField("Daily room rate", text: $dailyRoomRate)
                            .keyboardType(.decimalPad)
                    }
                }
                
                // Submit
                Section {
                    Button { admitPatient() } label: {
                        Text("Admit Patient")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Admit Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Admitted", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("\(patient.personalInfo.fullName) → Ward \(wardNumber), Bed \(bedNumber)")
            }
        }
    }
    
    private func admitPatient() {
        let admission = Admission(
            patientId: patient.id,
            patientName: patient.personalInfo.fullName,
            doctorIds: Array(selectedDoctorIds),
            nurseId: selectedNurseId.isEmpty ? nil : selectedNurseId,
            bedNumber: bedNumber,
            wardNumber: wardNumber,
            status: .admitted,
            diagnosis: diagnosis.isEmpty ? nil : diagnosis,
            dailyRoomRate: Double(dailyRoomRate) ?? 0
        )
        dataStore.admitPatient(admission)
        HapticManager.success()
        showSuccess = true
    }
}
