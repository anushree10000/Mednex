//
//  NursePatientDetailView.swift
//  MedNex
//
//  Patient detail for the nurse — profile header, info, pending requests,
//  and a clean vitals history that is professional and low-color.

import SwiftUI

struct NursePatientDetailView: View {
    let patient: Patient
    let appState: AppState
    @Environment(DataStore.self) private var dataStore

    @State private var showRecordVitals = false

    private var admissionInfo: Admission? {
        dataStore.admissions.first(where: {
            ($0.patientId == patient.id || $0.patientId == patient.userId) && $0.status == .admitted
        })
    }

    private var patientVitals: [VitalRecord] {
        dataStore.vitalRecords
            .filter { $0.patientId == patient.id || $0.patientId == patient.userId }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var pendingRequests: [VitalsRequest] {
        dataStore.vitalsRequests.filter { $0.patientId == patient.id && $0.status == .pending }
    }

    var body: some View {
        List {
            // ── Profile Header ───────────────────────────────────────
            Section {
                AdminProfileHeader(
                    name: patient.personalInfo.fullName,
                    imageURL: patient.profileImageURL,
                    subtitle: "\(patient.personalInfo.age) yrs · \(patient.personalInfo.gender.displayName)",
                    badge: admissionInfo.map { "Ward \($0.wardNumber ?? "N/A") · Bed \($0.bedNumber ?? "N/A")" },
                    badgeColor: MedNexTheme.Colors.info,
                    avatarColor: MedNexTheme.Colors.primary
                )
            }

            // ── Patient Info ─────────────────────────────────────────
            Section("Patient Info") {
                PlainInfoRow(label: "Blood Group", value: patient.medicalInfo.bloodType.rawValue)
                PlainInfoRow(label: "Phone", value: patient.personalInfo.phone.isEmpty ? "Not provided" : patient.personalInfo.phone)
                PlainInfoRow(
                    label: "Allergies",
                    value: patient.medicalInfo.allergies.isEmpty ? "None recorded" : patient.medicalInfo.allergies.joined(separator: ", ")
                )
                if !patient.medicalInfo.chronicConditions.isEmpty {
                    PlainInfoRow(
                        label: "Conditions",
                        value: patient.medicalInfo.chronicConditions.joined(separator: ", ")
                    )
                }
                if !patient.personalInfo.address.isEmpty || !patient.personalInfo.city.isEmpty {
                    let parts = [patient.personalInfo.address, patient.personalInfo.city, patient.personalInfo.state].filter { !$0.isEmpty }
                    PlainInfoRow(label: "Address", value: parts.joined(separator: ", "))
                }
            }

            // ── Pending Requests ──────────────────────────────────────
            if !pendingRequests.isEmpty {
                Section("Pending Requests") {
                    ForEach(pendingRequests) { request in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Vitals Requested")
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)
                                Text("By doctor at \(request.createdAt.timeOnly)")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()
                            Image(systemName: "clock")
                                .foregroundStyle(Color.secondary)
                                .font(.body.weight(.medium))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // ── Record Vitals CTA ─────────────────────────────────────
            Section {
                Button {
                    HapticManager.selection()
                    showRecordVitals = true
                } label: {
                    Label("Record Vitals", systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(MedNexTheme.Colors.primary, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            }

            // ── Vitals History ────────────────────────────────────────
            Section {
                if patientVitals.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: MedNexTheme.Spacing.sm) {
                            Image(systemName: "heart.text.clipboard")
                                .font(.title)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            Text("No vitals recorded yet")
                                .font(.subheadline)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                        .padding(.vertical, MedNexTheme.Spacing.lg)
                        Spacer()
                    }
                } else {
                    ForEach(patientVitals) { vital in
                        VitalDetailRow(vital: vital)
                    }
                }
            } header: {
                Text("Vitals History · \(patientVitals.count)")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Patient Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRecordVitals) {
            let mockAssignment = NursePatientAssignment(
                staffId: appState.currentUser?.id ?? "",
                patientId: patient.id
            )
            let info = NursePatientInfo(
                assignment: mockAssignment,
                patient: patient,
                admission: admissionInfo,
                latestVital: patientVitals.first,
                displayName: patient.personalInfo.fullName
            )
            NavigationStack {
                NurseVitalsFormView(patientInfo: info)
            }
        }
    }
}

// MARK: - Vital Detail Row
//
//  Redesigned for professional clarity:
//  • Timestamp + relative time in header
//  • Metrics as plain AdminStatItem-style rows — icon tint only, no background fill colors
//  • No rainbow chips — a single neutral summary line replaces them
//  • Status badge (Normal / Abnormal) at bottom

struct VitalDetailRow: View {
    let vital: VitalRecord

    var body: some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {

            // Timestamp header
            HStack {
                Text(vital.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.footnote.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.secondary)
                Spacer()
                Text(vital.timestamp.relative)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }

            // Metric rows
            let metrics = buildMetrics()
            if !metrics.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(metrics.enumerated()), id: \.offset) { idx, metric in
                        if idx > 0 { Divider() }
                        HStack {
                            Image(systemName: metric.icon)
                                .font(.body.weight(.regular))
                                .foregroundStyle(Color.secondary)
                                .frame(width: 24, height: 24)
                            
                            Text(metric.label)
                                .font(.body)
                                .foregroundStyle(Color.primary)
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Text(metric.value)
                                    .font(.body.weight(metric.statusColor != nil ? .bold : .regular).monospacedDigit())
                                    .foregroundStyle(metric.statusColor ?? Color.primary)
                                
                                if metric.statusColor == .red {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.red)
                                } else if metric.statusColor == .orange {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.orange)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.top, 4)
            }

            // Notes
            if !vital.notes.isEmpty {
                HStack(alignment: .top, spacing: MedNexTheme.Spacing.xs) {
                    Image(systemName: "note.text")
                        .font(.body)
                        .foregroundStyle(Color.secondary)
                        .frame(width: 24, height: 24)
                    Text(vital.notes)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, MedNexTheme.Spacing.xs)
    }

    // ── Metric model ─────────────────────────────────────────────────
    private struct VitalMetric {
        let icon: String
        let label: String
        let value: String
        let statusColor: Color?
    }

    private func getHeartRateColor(_ hr: Double) -> Color? {
        if hr > 120 || hr < 50 { return .red }
        if hr > 100 || hr < 60 { return .orange }
        return nil
    }

    private func getSpO2Color(_ spo2: Double) -> Color? {
        if spo2 < 90 { return .red }
        if spo2 < 95 { return .orange }
        return nil
    }

    private func getBPColor(sys: Double) -> Color? {
        if sys > 180 || sys < 90 { return .red }
        if sys > 140 || sys < 100 { return .orange }
        return nil
    }
    
    private func getTempColor(_ temp: Double) -> Color? {
        if temp > 103 { return .red }
        if temp > 100.4 || temp < 96 { return .orange }
        return nil
    }

    private func buildMetrics() -> [VitalMetric] {
        var result: [VitalMetric] = []
        if let hrValue = vital.heartRate, let hrFormatted = vital.heartRateFormatted {
            result.append(.init(icon: "heart", label: "Heart Rate", value: hrFormatted, statusColor: getHeartRateColor(hrValue)))
        }
        if let bpFormatted = vital.bloodPressureFormatted {
            let bpColor: Color? = (vital.bloodPressureSystolic != nil) ? getBPColor(sys: vital.bloodPressureSystolic!) : nil
            result.append(.init(icon: "waveform.path.ecg", label: "Blood Pressure", value: bpFormatted, statusColor: bpColor))
        }
        if let spo2Value = vital.oxygenSaturation, let spFormatted = vital.spO2Formatted {
            result.append(.init(icon: "lungs", label: "SpO₂", value: spFormatted, statusColor: getSpO2Color(spo2Value)))
        }
        if let tempValue = vital.temperature, let tmpFormatted = vital.temperatureFormatted {
            result.append(.init(icon: "thermometer", label: "Temperature", value: tmpFormatted, statusColor: getTempColor(tempValue)))
        }
        if let rrValue = vital.respiratoryRate {
            let rrColor = (rrValue > 25 || rrValue < 12) ? Color.orange : nil
            result.append(.init(icon: "wind", label: "Respiratory Rate", value: "\(Int(rrValue)) /min", statusColor: rrColor))
        }
        if let wtValue = vital.weight {
            result.append(.init(icon: "scalemass", label: "Weight", value: "\(String(format: "%.1f", wtValue)) kg", statusColor: nil))
        }
        if let bgValue = vital.bloodGlucose {
            let bgColor: Color? = (bgValue > 200 || bgValue < 70) ? .orange : nil
            result.append(.init(icon: "drop", label: "Blood Glucose", value: "\(Int(bgValue)) mg/dL", statusColor: bgColor))
        }
        return result
    }
}

// MARK: - Vital History Card (backward compat)

struct VitalHistoryCard: View {
    let vital: VitalRecord

    var body: some View {
        GlassCard(padding: MedNexTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(vital.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    Spacer()
                    Text(vital.timestamp.relative)
                        .font(MedNexTheme.Typography.caption2)
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
                HStack(spacing: 8) {
                    if let hr = vital.heartRateFormatted    { pill(hr, icon: "heart.fill",         color: .red) }
                    if let bp = vital.bloodPressureFormatted { pill(bp, icon: "waveform.path.ecg", color: MedNexTheme.Colors.info) }
                    if let sp = vital.spO2Formatted          { pill(sp, icon: "lungs.fill",        color: MedNexTheme.Colors.primary) }
                    if let t  = vital.temperatureFormatted   { pill(t,  icon: "thermometer.medium",color: .orange) }
                }
                if !vital.notes.isEmpty {
                    Text(vital.notes)
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        .padding(.top, 2)
                }
            }
        }
    }

    private func pill(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
        .foregroundStyle(color)
    }
}

// MARK: - Plain Info Row
struct PlainInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(Color.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}
