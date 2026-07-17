//
//  PatientAdmissionView.swift
//  MedNex
//
//  Patient-facing read-only admission details view.
//  Admissions are managed by admin — patients can only view their status.

import SwiftUI

struct PatientAdmissionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    
    private var currentAdmission: Admission? {
        dataStore.admissions.first(where: { $0.patientId == dataStore.patient.id && $0.status == .admitted })
    }
    
    private var pastAdmissions: [Admission] {
        dataStore.admissions
            .filter { $0.patientId == dataStore.patient.id && $0.status != .admitted }
            .sorted { $0.admissionDate > $1.admissionDate }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if let admission = currentAdmission {
                    // Active Admission
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bed.double.fill")
                                    .font(.title2)
                                    .foregroundStyle(MedNexTheme.Colors.info)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Currently Admitted")
                                        .font(.headline)
                                    Text("Since \(admission.admissionDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                StatusBadge(text: "Active", color: MedNexTheme.Colors.info)
                            }
                        }
                    } header: {
                        Text("Admission Status")
                    }
                    
                    // Room Details
                    Section("Room Details") {
                        admissionRow(icon: "building.2.fill", label: "Ward", value: admission.wardNumber ?? "—")
                        admissionRow(icon: "bed.double", label: "Bed", value: admission.bedNumber ?? "—")
                        if admission.dailyRoomRate > 0 {
                            admissionRow(icon: "indianrupeesign.circle", label: "Daily Rate", value: "₹\(Int(admission.dailyRoomRate))")
                        }
                    }
                    
                    // Assigned Doctors
                    if !admission.doctorIds.isEmpty {
                        Section("Assigned Doctors") {
                            ForEach(admission.doctorIds, id: \.self) { docId in
                                if let doctor = dataStore.doctors.first(where: { $0.id == docId }) {
                                    HStack(spacing: 12) {
                                        AvatarView(name: doctor.name, size: 36, backgroundColor: MedNexTheme.Colors.doctorTint)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(doctor.name)
                                                .font(.subheadline.weight(.medium))
                                            Text(doctor.specialty.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                } else {
                                    Label("Doctor", systemImage: "stethoscope")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    
                    // Diagnosis
                    if let diagnosis = admission.diagnosis, !diagnosis.isEmpty {
                        Section("Diagnosis") {
                            Text(diagnosis)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    }
                    
                } else {
                    // Not Currently Admitted
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(MedNexTheme.Colors.success)
                            
                            Text("Not Currently Admitted")
                                .font(.headline)
                            
                            Text("You are not currently admitted to the hospital. If you need admission, please contact the hospital administration.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }
                
                // Past Admissions
                if !pastAdmissions.isEmpty {
                    Section("Past Admissions") {
                        ForEach(pastAdmissions) { admission in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(admission.admissionDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    StatusBadge(text: admission.status.displayName, color: Color(hex: admission.status.color))
                                }
                                
                                if let diagnosis = admission.diagnosis, !diagnosis.isEmpty {
                                    Text(diagnosis)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if let discharge = admission.dischargeDate {
                                    Text("Discharged: \(discharge.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Admission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func admissionRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(MedNexTheme.Colors.info)
                .frame(width: 22)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}
