//
//  PatientDetailView.swift
//  MedNex
//
//  Patient detail — admission status is the focal point.
//  Medical info uses AdminDetailRow; appointments/bills are plain lists.

import SwiftUI

struct PatientDetailView: View {
    let patient: Patient
    @Environment(DataStore.self) private var dataStore
    @State private var showAdmitSheet = false
    @State private var showDischargeConfirm = false
    
    private var patientAppointments: [Appointment] {
        dataStore.appointments.filter { $0.patientId == patient.id }.sorted { $0.dateTime > $1.dateTime }
    }
    
    private var patientBills: [Bill] {
        dataStore.bills.filter { $0.patientId == patient.id }.sorted { $0.createdAt > $1.createdAt }
    }

    private var patientLabTests: [LabTest] {
        dataStore.labTests.filter { $0.patientId == patient.id }.sorted { $0.orderedAt > $1.orderedAt }
    }

    private var patientAdmissions: [Admission] {
        dataStore.admissions.filter { $0.patientId == patient.id }.sorted { $0.admissionDate > $1.admissionDate }
    }

    private var patientPrescriptions: [Prescription] {
        dataStore.prescriptions.filter { $0.patientId == patient.id }.sorted { $0.createdAt > $1.createdAt }
    }
    
    private var currentAdmission: Admission? {
        dataStore.admissions.first { $0.patientId == patient.id && $0.status == .admitted }
    }
    
    var body: some View {
        List {
            // Profile
            AdminProfileHeader(
                name: patient.personalInfo.fullName,
                imageURL: patient.profileImageURL,
                avatarColor: MedNexTheme.Colors.patientTint
            )
            
            // #17: Patient ID
            Section {
                HStack {
                    Text("Patient ID")
                        .font(.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    Spacer()
                    Text("MNX-\(String(patient.id.prefix(6)).uppercased())")
                        .font(.subheadline.monospaced().weight(.medium))
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
            }
            
            // MARK: Admission — the focal point
            if let admission = currentAdmission {
                Section {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                        HStack {
                            Text("Admitted")
                                .font(.headline)
                                .foregroundStyle(MedNexTheme.Colors.info)
                            Spacer()
                            Text(admission.admissionDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        }
                        
                        if admission.wardNumber != nil || admission.bedNumber != nil {
                            HStack(spacing: MedNexTheme.Spacing.md) {
                                if let ward = admission.wardNumber {
                                    Text("Ward \(ward)")
                                }
                                if let bed = admission.bedNumber {
                                    Text("Bed \(bed)")
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                        
                        if !admission.doctorIds.isEmpty {
                            let names = admission.doctorIds.compactMap { id in
                                dataStore.doctors.first(where: { $0.id == id })?.name
                            }
                            if !names.isEmpty {
                                Text(names.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                        }
                    }
                    
                    Button("Discharge", role: .destructive) {
                        showDischargeConfirm = true
                    }
                }
            } else {
                Section {
                    Button {
                        showAdmitSheet = true
                    } label: {
                        Text("Admit Patient")
                            .font(.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            
            // Personal — uses AdminDetailRow
            Section("Personal") {
                AdminDetailRow(icon: "phone.fill", label: "Phone", value: patient.personalInfo.phone.isEmpty ? "—" : patient.personalInfo.phone)
                if patient.personalInfo.age > 0 {
                    AdminDetailRow(icon: "calendar", label: "Age", value: "\(patient.personalInfo.age) years")
                }
                AdminDetailRow(icon: "person.fill", label: "Gender", value: patient.personalInfo.gender.rawValue.capitalized)
                if !patient.personalInfo.address.isEmpty {
                    AdminDetailRow(icon: "mappin.circle.fill", label: "Address", value: patient.personalInfo.address)
                }
            }
            
            // Medical — uses AdminDetailRow where key-value helps
            Section("Medical") {
                AdminDetailRow(icon: "drop.fill", label: "Blood Type", value: patient.medicalInfo.bloodType.rawValue, valueColor: MedNexTheme.Colors.error)
                
                if !patient.medicalInfo.allergies.isEmpty {
                    HStack(alignment: .top) {
                        Text("Allergies")
                            .font(.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        Spacer()
                        Text(patient.medicalInfo.allergies.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.warning)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if !patient.medicalInfo.chronicConditions.isEmpty {
                    HStack(alignment: .top) {
                        Text("Conditions")
                            .font(.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        Spacer()
                        Text(patient.medicalInfo.chronicConditions.joined(separator: ", "))
                            .font(.subheadline)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            
            // Emergency contacts — plain rows, no AdminDetailRow
            if !patient.emergencyContacts.isEmpty {
                Section("Emergency Contact") {
                    ForEach(patient.emergencyContacts, id: \.phone) { contact in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(contact.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text(contact.phone)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                            Text(contact.relationship)
                                .font(.caption)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        }
                    }
                }
            }
            
            // Admission history — complete timeline
            if !patientAdmissions.isEmpty {
                Section("Admission History · \(patientAdmissions.count)") {
                    ForEach(patientAdmissions) { admission in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(admission.status.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(admission.status == .admitted ? MedNexTheme.Colors.info : MedNexTheme.Colors.textPrimary)
                                Spacer()
                                Text(admission.admissionDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                            
                            Text("Discharged: \(admission.dischargeDate?.formatted(date: .abbreviated, time: .shortened) ?? "—")")
                                .font(.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            
                            let doctorNames = admission.doctorIds.compactMap { id in
                                dataStore.doctors.first(where: { $0.id == id })?.name
                            }
                            if !doctorNames.isEmpty {
                                Text("Doctors: \(doctorNames.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                            
                            if let nurseId = admission.nurseId,
                               let nurseName = dataStore.staff.first(where: { $0.id == nurseId })?.name {
                                Text("Nurse: \(nurseName)")
                                    .font(.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
            // Appointments — complete history
            if !patientAppointments.isEmpty {
                Section("Appointments · \(patientAppointments.count)") {
                    ForEach(patientAppointments) { appt in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(appt.doctorName.isEmpty ? "Doctor" : "Dr. \(appt.doctorName)")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text(appt.status.displayName)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(appt.status == .completed ? MedNexTheme.Colors.success : MedNexTheme.Colors.textSecondary)
                            }
                            Text("\(appt.dateTime.formatted(date: .abbreviated, time: .shortened)) · \(appt.type.displayName)")
                                .font(.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            if !appt.notes.isEmpty {
                                Text(appt.notes)
                                    .font(.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
            // Lab tests — complete history
            if !patientLabTests.isEmpty {
                Section("Lab Tests · \(patientLabTests.count)") {
                    ForEach(patientLabTests) { test in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(test.testName)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text(test.status.displayName)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(test.status == .completed ? MedNexTheme.Colors.success : MedNexTheme.Colors.textSecondary)
                            }
                            Text("Ordered \(test.orderedAt.formatted(date: .abbreviated, time: .shortened)) · Dr. \(test.doctorName)")
                                .font(.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            if let completedAt = test.completedAt {
                                Text("Completed \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
            // Prescriptions — full history
            if !patientPrescriptions.isEmpty {
                Section("Prescriptions · \(patientPrescriptions.count)") {
                    ForEach(patientPrescriptions) { prescription in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(prescription.doctorName.isEmpty ? "Prescription" : "Dr. \(prescription.doctorName)")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text(prescription.status.displayName)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(prescription.status == .active ? MedNexTheme.Colors.success : MedNexTheme.Colors.textSecondary)
                            }
                            Text(prescription.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            if !prescription.diagnosis.isEmpty {
                                Text(prescription.diagnosis)
                                    .font(.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
            // Bills — complete history
            if !patientBills.isEmpty {
                Section("Bills · \(patientBills.count)") {
                    ForEach(patientBills) { bill in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("₹\(Int(bill.totalAmount))")
                                    .font(.subheadline.weight(.semibold).monospacedDigit())
                                Spacer()
                                Text(bill.status.displayName)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(bill.status == .paid ? MedNexTheme.Colors.success : MedNexTheme.Colors.warning)
                            }
                            Text("Raised \(bill.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            if let paidAt = bill.paidAt {
                                Text("Paid \(paidAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Patient")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdmitSheet) {
            AdminAdmitPatientSheet(patient: patient)
        }
        .alert("Discharge Patient?", isPresented: $showDischargeConfirm) {
            Button("Discharge", role: .destructive) {
                if let admission = currentAdmission {
                    dataStore.dischargePatient(admission.id)
                    HapticManager.success()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mark \(patient.personalInfo.fullName) as discharged.")
        }
    }
}
