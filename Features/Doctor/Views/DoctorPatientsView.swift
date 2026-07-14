//
//  DoctorPatientsView.swift
//  MedNex
//
//  Shows admission-based patients + appointment-derived patients for doctors.

import SwiftUI

struct DoctorPatientsView: View {
    let appState: AppState
    @State private var searchText = ""
    @State private var selectedAppointment: Appointment?
    @State private var selectedAdmittedPatient: AdmittedPatientInfo?
    @Environment(DataStore.self) private var dataStore
    
    var filterForToday: Bool = false
    
    // MARK: - Admitted Patients (from admissions where doctor is assigned)
    
    private var admittedPatients: [AdmittedPatientInfo] {
        let activeAdmissions = dataStore.admissions.filter { $0.status == .admitted }
        return activeAdmissions.compactMap { admission in
            let patient = dataStore.allPatients.first(where: { $0.id == admission.patientId || $0.userId == admission.patientId })
            let name = patient?.personalInfo.fullName ?? admission.patientName ?? "Unknown"
            return AdmittedPatientInfo(
                admission: admission,
                patient: patient,
                displayName: name
            )
        }
    }
    
    private var filteredAdmittedPatients: [AdmittedPatientInfo] {
        if searchText.isEmpty { return admittedPatients }
        return admittedPatients.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }
    
    // MARK: - Appointment-Based Patients
    
    private var uniqueAppointments: [Appointment] {
        let appointmentsToConsider = filterForToday ? dataStore.appointments.filter { Calendar.current.isDateInToday($0.dateTime) } : dataStore.appointments
        let grouped = Dictionary(grouping: appointmentsToConsider, by: \.patientId)
        return grouped.compactMap { (_, appointments) in
            appointments.sorted(by: { $0.dateTime > $1.dateTime }).first
        }
        .sorted { $0.dateTime > $1.dateTime }
    }
    
    var filteredAppointments: [Appointment] {
        if searchText.isEmpty { return uniqueAppointments }
        return uniqueAppointments.filter { $0.patientName.localizedCaseInsensitiveContains(searchText) || $0.type.displayName.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.md) {
                MedNexSearchBar(text: $searchText, placeholder: "Search patients...")
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                
                // Admitted Patients Section
                if !filteredAdmittedPatients.isEmpty && !filterForToday {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                        SectionHeader(title: "Admitted Patients (\(filteredAdmittedPatients.count))")
                            .padding(.horizontal, MedNexTheme.Spacing.sm)
                        
                        DoctorGroupedSection {
                            ForEach(Array(filteredAdmittedPatients.enumerated()), id: \.element.id) { index, info in
                                Button {
                                    selectedAdmittedPatient = info
                                } label: {
                                    DoctorGroupedRow(showDivider: index < filteredAdmittedPatients.count - 1) {
                                        HStack(spacing: MedNexTheme.Spacing.sm) {
                                            AvatarView(
                                                name: info.displayName,
                                                imageURL: info.patient?.profileImageURL,
                                                size: 36,
                                                backgroundColor: MedNexTheme.Colors.patientTint
                                            )
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(info.displayName)
                                                    .font(.system(.body, weight: .semibold))
                                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                                
                                                HStack(spacing: MedNexTheme.Spacing.xs) {
                                                    if let ward = info.admission.wardNumber {
                                                        Text(ward)
                                                    }
                                                    if let bed = info.admission.bedNumber {
                                                        Text(bed)
                                                    }
                                                }
                                                .font(.system(.caption2, weight: .medium))
                                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 8) {
                                                StatusBadge(text: "Admitted", color: MedNexTheme.Colors.info)
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, MedNexTheme.Spacing.md)
                    }
                }
                
                // Appointment-Based Patients Section
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                    if !filterForToday {
                        SectionHeader(title: "From Appointments")
                            .padding(.horizontal, MedNexTheme.Spacing.sm)
                    }
                    
                    if filteredAppointments.isEmpty && filteredAdmittedPatients.isEmpty {
                        EmptyStateView(icon: "person.2", title: "No Patients", message: "Patients from your appointments will appear here.")
                            .padding(.top, MedNexTheme.Spacing.xxl)
                    } else if filteredAppointments.isEmpty {
                        EmptyStateView(icon: "calendar", title: "No Appointment Patients", message: "No patients from appointments.")
                            .padding(.top, MedNexTheme.Spacing.md)
                    } else {
                        DoctorGroupedSection {
                            ForEach(Array(filteredAppointments.enumerated()), id: \.element.id) { index, appointment in
                                Button {
                                    selectedAppointment = appointment
                                } label: {
                                    DoctorGroupedRow(showDivider: index < filteredAppointments.count - 1) {
                                        HStack(spacing: MedNexTheme.Spacing.sm) {
                                            AvatarView(
                                                name: appointment.patientName,
                                                imageURL: dataStore.patientProfileImages[appointment.patientId],
                                                size: 36,
                                                backgroundColor: MedNexTheme.Colors.patientTint
                                            )
                                            
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(appointment.patientName)
                                                    .font(.system(.body, weight: .semibold))
                                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                                
                                                Text(appointment.type.displayName)
                                                    .font(.system(.caption, weight: .medium))
                                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                                
                                                Text("Last visit: \(appointment.dateTime.relative)")
                                                    .font(.system(.caption2, weight: .regular))
                                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, MedNexTheme.Spacing.md)
                        .padding(.bottom, MedNexTheme.Spacing.xxl)
                    }
                }
            }
        }
        .navigationDestination(item: $selectedAppointment) { appointment in
            DoctorPatientDetailView(appState: appState, appointment: appointment)
        }
        .navigationDestination(item: $selectedAdmittedPatient) { info in
            DoctorAdmittedPatientDetailView(appState: appState, info: info)
        }
        .scrollContentBackground(.hidden)
        .doctorFlowBackground()
    }
}

// MARK: - Admitted Patient Info

struct AdmittedPatientInfo: Identifiable, Hashable {
    var id: String { admission.id }
    let admission: Admission
    let patient: Patient?
    let displayName: String
}

// MARK: - Doctor Admitted Patient Detail View

struct DoctorAdmittedPatientDetailView: View {
    let appState: AppState
    let info: AdmittedPatientInfo
    @Environment(DataStore.self) private var dataStore
    
    private var patientVitals: [VitalRecord] {
        dataStore.vitalRecords
            .filter { $0.patientId == info.admission.patientId }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    private var patientLabTests: [LabTest] {
        dataStore.labTests.filter { $0.patientId == info.admission.patientId }
    }
    
    private var patientPrescriptions: [Prescription] {
        dataStore.prescriptions.filter { $0.patientId == info.admission.patientId }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Header
                VStack(spacing: MedNexTheme.Spacing.md) {
                    AvatarView(
                        name: info.displayName,
                        imageURL: info.patient?.profileImageURL,
                        size: 80,
                        backgroundColor: MedNexTheme.Colors.patientTint
                    )
                    
                    Text(info.displayName)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    
                    StatusBadge(text: "Admitted", color: MedNexTheme.Colors.info)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, MedNexTheme.Spacing.lg)
                
                // Admission Info
                DoctorCard(cornerRadius: MedNexTheme.CornerRadius.lg, padding: MedNexTheme.Spacing.md) {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        Text("Admission Details")
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(MedNexTheme.Colors.info)
                        
                        HStack(alignment: .center, spacing: MedNexTheme.Spacing.lg) {
                            if let ward = info.admission.wardNumber {
                                Text(ward)
                                    .font(.system(.body, weight: .medium))
                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                            }
                            if let bed = info.admission.bedNumber {
                                Text(bed)
                                    .font(.system(.body, weight: .medium))
                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                            }
                        }
                        
                        if let diagnosis = info.admission.diagnosis, !diagnosis.isEmpty {
                            Divider()
                            Text("Diagnosis: \(diagnosis)")
                                .font(.system(.caption, weight: .regular))
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                
                // Patient Details
                if let patient = info.patient {
                    DoctorCard(cornerRadius: MedNexTheme.CornerRadius.lg, padding: MedNexTheme.Spacing.md) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Patient Info")
                                .font(.system(.body, weight: .semibold))
                                .foregroundStyle(MedNexTheme.Colors.primary)
                                .padding(.bottom, MedNexTheme.Spacing.md)
                            
                            detailRow(icon: "person.text.rectangle", title: "Age / Sex",
                                value: "\(patient.personalInfo.age) yrs, \(patient.personalInfo.gender.displayName)")
                            Divider().padding(.vertical, MedNexTheme.Spacing.xs)
                            detailRow(icon: "drop.fill", title: "Blood Group",
                                value: patient.medicalInfo.bloodType.rawValue, iconColor: .red)
                            if !patient.medicalInfo.allergies.isEmpty {
                                Divider().padding(.vertical, MedNexTheme.Spacing.xs)
                                detailRow(icon: "allergens", title: "Allergies",
                                    value: patient.medicalInfo.allergies.joined(separator: ", "), iconColor: .orange)
                            }
                        }
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                }
                
                // Latest Vitals
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                    HStack {
                        SectionHeader(title: "Vitals")
                        Spacer()
                        if let nurseId = info.admission.nurseId, !nurseId.isEmpty {
                            let userId = appState.currentUser?.id ?? ""
                            let hasPendingRequest = dataStore.vitalsRequests.contains { $0.patientId == info.admission.patientId && $0.status == .pending && $0.doctorId == userId }
                            
                            Button {
                                if !userId.isEmpty {
                                    dataStore.requestVitals(doctorId: userId, patientId: info.admission.patientId, nurseId: nurseId)
                                    HapticManager.success()
                                }
                            } label: {
                                if hasPendingRequest {
                                    Label("Requested", systemImage: "checkmark.circle.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(MedNexTheme.Colors.success)
                                } else {
                                    Label("Request", systemImage: "arrow.triangle.2.circlepath")
                                        .font(.caption.weight(.semibold))
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(hasPendingRequest ? MedNexTheme.Colors.success : MedNexTheme.Colors.primary)
                            .disabled(hasPendingRequest)
                        }
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                    
                    if patientVitals.isEmpty {
                        DoctorCard {
                            Label("No vitals recorded yet.", systemImage: "waveform.path.ecg")
                                .font(MedNexTheme.Typography.body)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, MedNexTheme.Spacing.md)
                    } else {
                        ForEach(patientVitals.prefix(5)) { vital in
                            DoctorCard(cornerRadius: MedNexTheme.CornerRadius.lg, padding: MedNexTheme.Spacing.md) {
                                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                                    Text(vital.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(.caption, weight: .semibold))
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    
                                    // Primary Vitals Grid
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 75), spacing: MedNexTheme.Spacing.md)], spacing: MedNexTheme.Spacing.md) {
                                        if let hr = vital.heartRateFormatted {
                                            vitalBox(icon: "heart.fill", label: "HR", value: hr, color: MedNexTheme.Colors.error)
                                        }
                                        if let bp = vital.bloodPressureFormatted {
                                            vitalBox(icon: "waveform.path.ecg", label: "BP", value: bp, color: MedNexTheme.Colors.info)
                                        }
                                        if let spo2 = vital.spO2Formatted {
                                            vitalBox(icon: "lungs.fill", label: "O₂", value: spo2, color: MedNexTheme.Colors.primary)
                                        }
                                        if let temp = vital.temperatureFormatted {
                                            vitalBox(icon: "thermometer.medium", label: "Temp", value: temp, color: .orange)
                                        }
                                    }
                                    
                                    // Secondary Vitals
                                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                                        if let rr = vital.respiratoryRate {
                                            HStack {
                                                Text("Respiratory Rate:")
                                                    .font(.system(.caption, weight: .medium))
                                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                                Spacer()
                                                Text("\(Int(rr)) breaths/min")
                                                    .font(.system(.caption, weight: .semibold))
                                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                            }
                                        }
                                        
                                        if let weight = vital.weight {
                                            HStack {
                                                Text("Weight:")
                                                    .font(.system(.caption, weight: .medium))
                                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                                Spacer()
                                                Text("\(String(format: "%.1f", weight)) kg")
                                                    .font(.system(.caption, weight: .semibold))
                                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                            }
                                        }
                                        
                                        if let height = vital.height {
                                            HStack {
                                                Text("Height:")
                                                    .font(.system(.caption, weight: .medium))
                                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                                Spacer()
                                                Text("\(String(format: "%.1f", height)) cm")
                                                    .font(.system(.caption, weight: .semibold))
                                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                            }
                                        }
                                        
                                        if let glucose = vital.bloodGlucose {
                                            HStack {
                                                Text("Blood Glucose:")
                                                    .font(.system(.caption, weight: .medium))
                                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                                Spacer()
                                                Text("\(Int(glucose)) mg/dL")
                                                    .font(.system(.caption, weight: .semibold))
                                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                            }
                                        }
                                    }
                                    
                                    // Notes
                                    if !vital.notes.isEmpty {
                                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                                            Text("Notes")
                                                .font(.system(.caption, weight: .semibold))
                                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                            Text(vital.notes)
                                                .font(.system(.caption, weight: .regular))
                                                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                                .padding(MedNexTheme.Spacing.sm)
                                                .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, MedNexTheme.Spacing.md)
                        }
                    }
                }
                
                // Lab Tests
                if !patientLabTests.isEmpty {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        SectionHeader(title: "Lab Tests (\(patientLabTests.count))")
                            .padding(.horizontal, MedNexTheme.Spacing.md)
                        
                        ForEach(patientLabTests.prefix(5)) { test in
                            DoctorCard(padding: MedNexTheme.Spacing.sm) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(test.testName)
                                            .font(MedNexTheme.Typography.subheadline.weight(.medium))
                                        Text(test.orderedAt.formatted(date: .abbreviated, time: .omitted))
                                            .font(MedNexTheme.Typography.caption)
                                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    }
                                    Spacer()
                                    StatusBadge(text: test.status.displayName, color: Color(hex: test.status.color))
                                }
                            }
                            .padding(.horizontal, MedNexTheme.Spacing.md)
                        }
                    }
                }
                
                // Prescriptions
                if !patientPrescriptions.isEmpty {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        SectionHeader(title: "Prescriptions (\(patientPrescriptions.count))")
                            .padding(.horizontal, MedNexTheme.Spacing.md)
                        
                        ForEach(patientPrescriptions.prefix(5)) { rx in
                            DoctorCard(padding: MedNexTheme.Spacing.sm) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(rx.diagnosis.isEmpty ? "Prescription" : rx.diagnosis)
                                            .font(MedNexTheme.Typography.subheadline.weight(.medium))
                                        Text("\(rx.medicines.count) medicines • \(rx.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                            .font(MedNexTheme.Typography.caption)
                                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    }
                                    Spacer()
                                    StatusBadge(text: rx.status.displayName, color: Color(hex: rx.status.color))
                                }
                            }
                            .padding(.horizontal, MedNexTheme.Spacing.md)
                        }
                    }
                }
                
                // Clinical Actions
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                    SectionHeader(title: "Actions")
                    
                    NavigationLink {
                        PrescriptionWriterView(appState: appState, initialPatientId: info.admission.patientId)
                    } label: {
                        actionRow(icon: "doc.text.fill", title: "Write Prescription", color: MedNexTheme.Colors.primary)
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        PatientMedicalHistoryView(appState: appState, patientId: info.admission.patientId, patientName: info.displayName)
                    } label: {
                        actionRow(icon: "folder.badge.person.crop", title: "Medical History", color: MedNexTheme.Colors.info)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .doctorFlowBackground()
    }
    
    private func detailRow(icon: String, title: String, value: String, iconColor: Color = MedNexTheme.Colors.textSecondary) -> some View {
        HStack(alignment: .center, spacing: MedNexTheme.Spacing.md) {
            Text(title)
                .font(.system(.caption, weight: .medium))
                .foregroundColor(MedNexTheme.Colors.textSecondary)
            
            Spacer(minLength: MedNexTheme.Spacing.sm)
            
            Text(value)
                .font(.system(.body, weight: .semibold))
                .foregroundColor(MedNexTheme.Colors.textPrimary)
                .lineLimit(1)
        }
        .padding(.vertical, MedNexTheme.Spacing.xs)
    }
    
    private func miniVital(icon: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).foregroundStyle(color).font(.caption)
            Text(value).font(MedNexTheme.Typography.caption2.weight(.medium))
        }
    }
    
    private func vitalBox(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .center, spacing: MedNexTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            
            Text(label)
                .font(.system(.caption2, weight: .medium))
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
            
            Text(value)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(MedNexTheme.Spacing.sm)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
    }
    
    private func actionRow(icon: String, title: String, color: Color) -> some View {
        HStack(alignment: .center, spacing: MedNexTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
            
            Text(title)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MedNexTheme.Colors.textTertiary)
        }
        .padding(MedNexTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
