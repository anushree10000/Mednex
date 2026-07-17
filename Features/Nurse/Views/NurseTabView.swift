//
//  NurseTabView.swift
//  MedNex
//
//  v3: Fixed patient row consistency; ruler-scale vitals picker.

import SwiftUI

// MARK: - Main Tab View

struct NurseTabView: View {
    let appState: AppState
    @State private var selectedTab = 0
    @State private var showProfile = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "heart.text.clipboard", value: 0) {
                NavigationStack {
                    NurseStationView(appState: appState, showProfile: $showProfile)
                        .toolbar { profileToolbarItem() }
                }
            }
            Tab("Patients", systemImage: "person.2.fill", value: 1) {
                NavigationStack {
                    NurseAssignedPatientsView(appState: appState)
                        .toolbar { profileToolbarItem() }
                }
            }
            Tab("Requests", systemImage: "bell.badge.fill", value: 2) {
                NavigationStack {
                    NurseVitalsRequestsView(appState: appState)
                        .toolbar { profileToolbarItem() }
                }
            }
        }
        .tint(MedNexTheme.Colors.primary)
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                NurseProfileView(appState: appState)
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

    @ToolbarContentBuilder
    private func profileToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                HapticManager.selection()
                showProfile = true
            } label: {
                AvatarView(
                    name: appState.currentUser?.displayName ?? "N",
                    imageURL: appState.currentUser?.profileImageURL,
                    size: 32,
                    backgroundColor: MedNexTheme.Colors.primary
                )
            }
        }
    }
}

// MARK: - Station (Dashboard)

struct NurseStationView: View {
    let appState: AppState
    @Binding var showProfile: Bool
    @Environment(DataStore.self) private var dataStore

    /// IDs of patients who are currently admitted (not discharged/transferred)
    private var admittedPatientIds: Set<String> {
        Set(dataStore.admissions.filter { $0.status == .admitted }.map(\.patientId))
    }
    private var pendingRequests: Int {
        dataStore.vitalsRequests.filter { $0.status == .pending && admittedPatientIds.contains($0.patientId) }.count
    }
    private var assignedCount: Int {
        // Deduplicate: count unique admitted patient IDs only
        Set(dataStore.nurseAssignments.map(\.patientId)).filter { admittedPatientIds.contains($0) }.count
    }
    private var todayVitals: Int {
        dataStore.vitalRecords.filter { Calendar.current.isDateInToday($0.timestamp) && admittedPatientIds.contains($0.patientId) }.count
    }
    private var recentVitals: [VitalRecord] {
        Array(dataStore.vitalRecords
            .filter { admittedPatientIds.contains($0.patientId) }
            .sorted { $0.timestamp > $1.timestamp }.prefix(5))
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome back,")
                        .font(.subheadline).foregroundStyle(MedNexTheme.Colors.textSecondary)
                    Text(appState.currentUser?.displayName ?? "Nurse")
                        .font(.title2.weight(.semibold)).foregroundStyle(MedNexTheme.Colors.textPrimary)
                }
                .padding(.vertical, MedNexTheme.Spacing.xs)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                HStack(spacing: 0) {
                    NurseStatMetric(value: "\(assignedCount)", label: "Patients")
                    Divider().padding(.horizontal, 16)
                    NurseStatMetric(value: "\(todayVitals)", label: "Vitals Today")
                    Divider().padding(.horizontal, 16)
                    NurseStatMetric(value: "\(pendingRequests)", label: "Requests", isAlert: pendingRequests > 0)
                }
                .padding(.vertical, MedNexTheme.Spacing.md)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if !recentVitals.isEmpty {
                Section("Recent Activity") {
                    ForEach(recentVitals) { vital in
                        NurseActivityRow(patientName: patientName(for: vital.patientId), vital: vital)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dashboard")
        .refreshable { await dataStore.refreshFromBackend() }
    }

    private func patientName(for patientId: String) -> String {
        if let p = dataStore.nursePatients.first(where: { $0.id == patientId || $0.userId == patientId }) { return p.personalInfo.fullName }
        return dataStore.admissions.first(where: { $0.patientId == patientId })?.patientName ?? "Patient"
    }
}

// MARK: - Nurse Stat Metric

struct NurseStatMetric: View {
    let value: String; let label: String
    var isAlert: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(value)
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(isAlert ? MedNexTheme.Colors.warning : MedNexTheme.Colors.textPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Nurse Activity Row
// Redesigned for HIG: minimal intervention, removing rainbow color chips.

struct NurseActivityRow: View {
    let patientName: String; let vital: VitalRecord

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(patientName)
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundStyle(Color.primary)
                Text("Vitals logged • \(vital.timestamp.relative)")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
            
            // Abnormality indicator if needed
            let status = evaluateStatus()
            if status.isAbnormal {
                Text(status.label)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundStyle(status.textColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.bgColor, in: Capsule())
            } else {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.secondary)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .padding(.vertical, 4)
    }
    
    private struct ActivityStatus {
        let isAbnormal: Bool
        let label: String
        let textColor: Color
        let bgColor: Color
    }
    
    private func evaluateStatus() -> ActivityStatus {
        var isAbnormal = false
        var label = ""
        var color: Color = .orange
        
        if let hr = vital.heartRate, hr > 100 || hr < 60 { isAbnormal = true; label = "Abnormal HR" }
        if let bp = vital.bloodPressureSystolic, bp > 140 || bp < 100 { isAbnormal = true; label = "Abnormal BP"; color = .red }
        if let spo2 = vital.oxygenSaturation, spo2 < 95 { isAbnormal = true; label = "Low SpO2"; color = .red }
        
        return ActivityStatus(
            isAbnormal: isAbnormal,
            label: label,
            textColor: color,
            bgColor: color.opacity(0.15)
        )
    }
}

// MARK: - Assigned Patients

struct NurseAssignedPatientsView: View {
    let appState: AppState
    @State private var searchText = ""
    @State private var selectedPatientForVitals: NursePatientInfo?
    @Environment(DataStore.self) private var dataStore

    /// Only show patients who are currently admitted — deduplicated by patientId
    private var assignedPatientInfos: [NursePatientInfo] {
        // Group assignments by patientId, keep the latest one per patient
        let grouped = Dictionary(grouping: dataStore.nurseAssignments, by: \.patientId)
        return grouped.compactMap { (patientId, assignments) -> NursePatientInfo? in
            // Only include patients with an active (admitted) admission
            guard let admission = dataStore.admissions.first(where: { $0.patientId == patientId && $0.status == .admitted }) else {
                return nil
            }
            // Use the most recent assignment
            let assignment = assignments.sorted(by: { $0.assignedDate > $1.assignedDate }).first!
            let patient = dataStore.nursePatients.first(where: { $0.id == patientId || $0.userId == patientId })
            let latestVital = dataStore.vitalRecords.filter { $0.patientId == patientId }
                .sorted { $0.timestamp > $1.timestamp }.first
            let name = patient?.personalInfo.fullName ?? admission.patientName ?? "Unknown"
            return NursePatientInfo(assignment: assignment, patient: patient, admission: admission, latestVital: latestVital, displayName: name)
        }
    }

    private var filteredPatients: [NursePatientInfo] {
        searchText.isEmpty ? assignedPatientInfos
            : assignedPatientInfos.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            if filteredPatients.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No Assigned Patients" : "No Results",
                    systemImage: "person.2.slash",
                    description: Text(searchText.isEmpty
                        ? "You have no patients assigned to you at this time."
                        : "Try a different search.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredPatients) { info in
                    if let patient = info.patient {
                        NavigationLink(destination: NursePatientDetailView(patient: patient, appState: appState)) {
                            NursePatientRowContent(info: info)
                        }
                    } else {
                        NursePatientRowContent(info: info)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("My Patients")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search patients…")
        .sheet(item: $selectedPatientForVitals) { info in
            NavigationStack { NurseVitalsFormView(patientInfo: info) }
        }
        .refreshable { await dataStore.refreshFromBackend() }
    }
}

// MARK: - Patient Row Content
//
//  Redesigned following HIG: Minimal color, scannable layout.
//  Shows Patient Name, Age, ID.
//  Shows Status indicator and exception highlights instead of all vitals.

struct NursePatientRowContent: View {
    let info: NursePatientInfo

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            
            // Left Column: Identification
            VStack(alignment: .leading, spacing: 4) {
                // Name
                Text(info.displayName)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                
                // Details (Ward / Bed only)
                HStack(spacing: 6) {
                    if let ward = info.admission?.wardNumber, let bed = info.admission?.bedNumber {
                        Text("\(ward) - \(bed)")
                    } else {
                        Text("No Location")
                    }
                }
                .font(.system(size: 15, weight: .regular, design: .default))
                .foregroundStyle(Color.secondary)
            }
            
            Spacer(minLength: 8)
            
            // Right Column: Status & Exceptions
            VStack(alignment: .trailing, spacing: 6) {
                let status = evaluateStatus()
                
                // Status Badge
                Text(status.label)
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .foregroundStyle(status.textColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.bgColor, in: Capsule())
                
                // Key Highlights (Exceptions only)
                if !status.exceptions.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        ForEach(status.exceptions.prefix(2), id: \.self) { exception in
                            Text(exception)
                                .font(.system(size: 12, weight: .medium, design: .default))
                                .foregroundStyle(status.textColor)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // Status Evaluation Logic
    private struct PatientStatus {
        let label: String
        let textColor: Color
        let bgColor: Color
        let exceptions: [String]
    }
    
    private func evaluateStatus() -> PatientStatus {
        guard let vital = info.latestVital else {
            return PatientStatus(label: "No Vitals", textColor: .secondary, bgColor: Color(UIColor.secondarySystemFill), exceptions: [])
        }
        
        var exceptions: [String] = []
        var isCritical = false
        var isWarning = false
        
        if let hr = vital.heartRate {
            if hr > 120 || hr < 50 { isCritical = true; exceptions.append("Abnormal HR") }
            else if hr > 100 || hr < 60 { isWarning = true; exceptions.append("HR: \(Int(hr))") }
        }
        
        if let bpSys = vital.bloodPressureSystolic {
            if bpSys > 180 || bpSys < 90 { isCritical = true; exceptions.append("Abnormal BP") }
            else if bpSys > 140 { isWarning = true; exceptions.append("High BP") }
            else if bpSys < 100 { isWarning = true; exceptions.append("Low BP") }
        }
        
        if let spo2 = vital.oxygenSaturation {
            if spo2 < 90 { isCritical = true; exceptions.append("Low SpO2") }
            else if spo2 < 95 { isWarning = true; exceptions.append("SpO2: \(Int(spo2))%") }
        }
        
        if isCritical {
            return PatientStatus(label: "Critical", textColor: .red, bgColor: Color.red.opacity(0.15), exceptions: exceptions)
        } else if isWarning || !exceptions.isEmpty {
            return PatientStatus(label: "Needs Attention", textColor: .orange, bgColor: Color.orange.opacity(0.15), exceptions: exceptions)
        } else {
            return PatientStatus(label: "Stable", textColor: .green, bgColor: Color.green.opacity(0.15), exceptions: [])
        }
    }
}

// MARK: - Nurse Patient Info

struct NursePatientInfo: Identifiable, Hashable {
    var id: String { assignment.id }
    let assignment: NursePatientAssignment
    let patient: Patient?
    let admission: Admission?
    let latestVital: VitalRecord?
    let displayName: String
}

// MARK: - Nurse Patient Card Content (backward compat)

struct NursePatientCardContent: View {
    let info: NursePatientInfo
    @Binding var selectedPatientForVitals: NursePatientInfo?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                HStack(spacing: MedNexTheme.Spacing.md) {
                    AvatarView(name: info.displayName, imageURL: info.patient?.profileImageURL,
                               size: 48, backgroundColor: MedNexTheme.Colors.patientTint)
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                        Text(info.displayName).font(MedNexTheme.Typography.headline)
                        HStack(spacing: MedNexTheme.Spacing.sm) {
                            if let w = info.admission?.wardNumber { Label(w, systemImage: "building.2.fill") }
                            if let b = info.admission?.bedNumber   { Label(b, systemImage: "bed.double") }
                        }
                        .font(MedNexTheme.Typography.caption).foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    Spacer()
                }
                if let vital = info.latestVital {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Vitals: \(vital.timestamp.relative)").font(MedNexTheme.Typography.caption).foregroundStyle(MedNexTheme.Colors.textTertiary)
                        HStack(spacing: MedNexTheme.Spacing.md) {
                            if let hr = vital.heartRateFormatted    { Label(hr, systemImage: "heart.fill").foregroundStyle(.red) }
                            if let bp = vital.bloodPressureFormatted { Label(bp, systemImage: "waveform.path.ecg").foregroundStyle(MedNexTheme.Colors.info) }
                            if let sp = vital.spO2Formatted          { Label(sp, systemImage: "lungs.fill").foregroundStyle(MedNexTheme.Colors.primary) }
                        }
                        .font(MedNexTheme.Typography.caption2)
                    }
                }
                Button { selectedPatientForVitals = info } label: {
                    Label("Record Vitals", systemImage: "heart.text.clipboard")
                        .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(MedNexTheme.Colors.primary, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Vitals Entry Form
//
//  Each vital row shows current value + a tappable pill that opens the
//  VitalRulerPickerView half-sheet. Sliders are gone — ruler scale only.

struct NurseVitalsFormView: View {
    let patientInfo: NursePatientInfo
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore

    @State private var heartRate: Double    = 72
    @State private var bpSystolic: Double   = 120
    @State private var bpDiastolic: Double  = 80
    @State private var oxygenSat: Double    = 98
    @State private var respRate: Double     = 16
    @State private var temperature: Double  = 98.6
    @State private var weight: Double       = 70
    @State private var bloodGlucose: Double = 100
    @State private var notes                = ""

    @State private var heartRateEnabled = true
    @State private var bpEnabled        = true
    @State private var spo2Enabled      = true
    @State private var rrEnabled        = true
    @State private var tempEnabled      = true
    @State private var weightEnabled    = false
    @State private var glucoseEnabled   = false

    @State private var activePicker: VitalPickerItem? = nil
    @State private var showSuccess = false

    private var isValid: Bool {
        heartRateEnabled || bpEnabled || spo2Enabled || rrEnabled || tempEnabled || weightEnabled || glucoseEnabled
    }

    var body: some View {
        Form {

            // Patient context
            Section {
                HStack(spacing: 12) {
                    AvatarView(name: patientInfo.displayName, imageURL: patientInfo.patient?.profileImageURL,
                               size: 44, backgroundColor: MedNexTheme.Colors.patientTint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(patientInfo.displayName).font(.headline)
                        if let w = patientInfo.admission?.wardNumber, let b = patientInfo.admission?.bedNumber {
                            Text("Ward \(w) · Bed \(b)").font(.caption).foregroundStyle(MedNexTheme.Colors.textTertiary)
                        }
                    }
                }
            }

            // Cardiovascular
            Section("Cardiovascular") {
                VitalFormRow(icon: "heart.fill", label: "Heart Rate",
                    displayValue: "\(Int(heartRate))", unit: "bpm",
                    color: .red, enabled: $heartRateEnabled) {
                    activePicker = VitalPickerItem(id: "hr", icon: "heart.fill", label: "Heart Rate",
                        unit: "bpm", color: .red, value: heartRate, range: 40...180, step: 1, decimals: 0)
                }
                VitalFormRow(icon: "waveform.path.ecg", label: "BP",
                    displayValue: "\(Int(bpSystolic))/\(Int(bpDiastolic))", unit: "mmHg",
                    color: MedNexTheme.Colors.info, enabled: $bpEnabled) {
                    activePicker = VitalPickerItem(id: "bps", icon: "waveform.path.ecg", label: "Systolic BP",
                        unit: "mmHg", color: MedNexTheme.Colors.info, value: bpSystolic, range: 70...200, step: 1, decimals: 0)
                }
                if bpEnabled {
                    VitalFormRow(icon: "waveform.path.ecg", label: "Diastolic BP",
                        displayValue: "\(Int(bpDiastolic))", unit: "mmHg",
                        color: MedNexTheme.Colors.info, enabled: $bpEnabled, hideToggle: true) {
                        activePicker = VitalPickerItem(id: "bpd", icon: "waveform.path.ecg", label: "Diastolic BP",
                            unit: "mmHg", color: MedNexTheme.Colors.info, value: bpDiastolic, range: 40...130, step: 1, decimals: 0)
                    }
                }
            }

            // Respiratory
            Section("Respiratory") {
                VitalFormRow(icon: "lungs.fill", label: "SpO₂",
                    displayValue: "\(Int(oxygenSat))", unit: "%",
                    color: MedNexTheme.Colors.primary, enabled: $spo2Enabled) {
                    activePicker = VitalPickerItem(id: "spo2", icon: "lungs.fill", label: "SpO₂",
                        unit: "%", color: MedNexTheme.Colors.primary, value: oxygenSat, range: 80...100, step: 1, decimals: 0)
                }
                VitalFormRow(icon: "wind", label: "Resp Rate",
                    displayValue: "\(Int(respRate))", unit: "/min",
                    color: MedNexTheme.Colors.info, enabled: $rrEnabled) {
                    activePicker = VitalPickerItem(id: "rr", icon: "wind", label: "Respiratory Rate",
                        unit: "/min", color: MedNexTheme.Colors.info, value: respRate, range: 8...40, step: 1, decimals: 0)
                }
            }

            // Other
            Section("Other") {
                VitalFormRow(icon: "thermometer.medium", label: "Temperature",
                    displayValue: String(format: "%.1f", temperature), unit: "°F",
                    color: .orange, enabled: $tempEnabled) {
                    activePicker = VitalPickerItem(id: "temp", icon: "thermometer.medium", label: "Temperature",
                        unit: "°F", color: .orange, value: temperature, range: 96.0...104.0, step: 0.1, decimals: 1)
                }
                VitalFormRow(icon: "scalemass", label: "Weight",
                    displayValue: String(format: "%.1f", weight), unit: "kg",
                    color: .purple, enabled: $weightEnabled) {
                    activePicker = VitalPickerItem(id: "wt", icon: "scalemass", label: "Weight",
                        unit: "kg", color: .purple, value: weight, range: 20...200, step: 0.5, decimals: 1)
                }
                VitalFormRow(icon: "drop.fill", label: "Blood Glucose",
                    displayValue: "\(Int(bloodGlucose))", unit: "mg/dL",
                    color: MedNexTheme.Colors.success, enabled: $glucoseEnabled) {
                    activePicker = VitalPickerItem(id: "bg", icon: "drop.fill", label: "Blood Glucose",
                        unit: "mg/dL", color: MedNexTheme.Colors.success, value: bloodGlucose, range: 50...400, step: 1, decimals: 0)
                }
            }

            // Notes
            Section("Notes") {
                TextField("Any observations…", text: $notes, axis: .vertical).lineLimit(2...4)
            }

            // Save
            Section {
                Button { saveVitals() } label: {
                    Label("Save Vitals", systemImage: "checkmark.circle.fill")
                        .font(.headline).frame(maxWidth: .infinity)
                }
                .disabled(!isValid)
            }
        }
        .navigationTitle("Record Vitals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        }
        .sheet(item: $activePicker) { item in
            VitalRulerPickerView(item: item) { newValue in
                commitValue(id: item.id, value: newValue)
            }
            .presentationDetents([.fraction(0.48)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(26)
            .presentationBackground(.clear)
        }
        .alert("Vitals Saved", isPresented: $showSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text("Vital signs have been recorded successfully.")
        }
    }

    private func commitValue(id: String, value: Double) {
        switch id {
        case "hr":   heartRate    = value
        case "bps":  bpSystolic   = value
        case "bpd":  bpDiastolic  = value
        case "spo2": oxygenSat    = value
        case "rr":   respRate     = value
        case "temp": temperature  = value
        case "wt":   weight       = value
        case "bg":   bloodGlucose = value
        default: break
        }
    }

    private func saveVitals() {
        let record = VitalRecord(
            id: UUID().uuidString,
            patientId: patientInfo.assignment.patientId,
            recordedBy: "Nurse",
            timestamp: Date(),
            bloodPressureSystolic:  bpEnabled       ? bpSystolic   : nil,
            bloodPressureDiastolic: bpEnabled       ? bpDiastolic  : nil,
            heartRate:              heartRateEnabled ? heartRate    : nil,
            temperature:            tempEnabled      ? temperature  : nil,
            respiratoryRate:        rrEnabled        ? respRate     : nil,
            oxygenSaturation:       spo2Enabled      ? oxygenSat   : nil,
            weight:                 weightEnabled    ? weight       : nil,
            height: nil,
            bloodGlucose:           glucoseEnabled   ? bloodGlucose : nil,
            notes: notes
        )
        dataStore.addVitalRecord(record)
        let pending = dataStore.vitalsRequests.filter {
            $0.patientId == patientInfo.assignment.patientId && $0.status == .pending
        }
        for req in pending { dataStore.completeVitalsRequest(req.id) }
        HapticManager.success()
        showSuccess = true
    }
}

// MARK: - Vital Form Row
//
//  Tappable row in the vitals form. Shows icon + label on the left,
//  value pill + toggle on the right. Tapping the pill (or the row when enabled)
//  opens the ruler picker half-sheet.

struct VitalFormRow: View {
    let icon: String
    let label: String
    let displayValue: String
    let unit: String
    let color: Color
    @Binding var enabled: Bool
    var hideToggle: Bool = false
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.regular))
                .foregroundStyle(enabled ? Color.primary : Color.secondary)
                .frame(width: 24, height: 24)

            Text(label)
                .font(.body)
                .foregroundStyle(enabled ? Color.primary : Color.secondary)

            Spacer()

            if enabled {
                Button(action: onTap) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(displayValue)
                            .font(.body.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Text(unit)
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.secondary.opacity(0.5))
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color(.secondarySystemFill), in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Text("—")
                    .font(.body)
                    .foregroundStyle(Color.secondary)
                    .padding(.trailing, 16)
            }

            if !hideToggle {
                Toggle("", isOn: $enabled)
                    .labelsHidden()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.15), value: enabled)
        .contentShape(Rectangle())
        .onTapGesture { if enabled { onTap() } }
    }
}

// MARK: - Vital Picker Item

struct VitalPickerItem: Identifiable {
    let id: String
    let icon: String
    let label: String
    let unit: String
    let color: Color
    let value: Double
    let range: ClosedRange<Double>
    let step: Double
    let decimals: Int
}

// MARK: - Vital Ruler Picker View
//
//  Half-sheet with a horizontal draggable ruler.
//  Reference: the weight/height scale pickers in the provided screenshots.
//
//  Design:
//    • Icon + label header
//    • Large bold value in accent color with unit
//    • Horizontal ruler: minor ticks every step, major ticks every 5 steps,
//      major tick labels below; center line in accent color acts as the pointer
//    • Drag left/right to change value with haptic feedback per tick
//    • "Confirm" button saves and dismisses

struct VitalRulerPickerView: View {
    let item: VitalPickerItem
    let onConfirm: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentValue: Double
    @State private var dragAccum: Double = 0   // accumulated drag in points

    private let tickSpacing: CGFloat = 12      // points between adjacent ticks
    private let majorEvery: Int = 5            // major tick every N ticks

    init(item: VitalPickerItem, onConfirm: @escaping (Double) -> Void) {
        self.item = item
        self.onConfirm = onConfirm
        _currentValue = State(initialValue: item.value)
    }

    private var displayString: String {
        item.decimals > 0
            ? String(format: "%.\(item.decimals)f", currentValue)
            : "\(Int(currentValue.rounded()))"
    }

    private var tickCount: Int {
        Int(((item.range.upperBound - item.range.lowerBound) / item.step).rounded()) + 1
    }

    private var currentTickIndex: Double {
        (currentValue - item.range.lowerBound) / item.step
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Icon + label ─────────────────────────────────────────
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 30, height: 30)
                    .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                Text(item.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
            }
            .padding(.top, 20)

            // ── Large value ──────────────────────────────────────────
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(displayString)
                    .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.07), value: displayString)
                Text(item.unit)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    .padding(.bottom, 8)
            }
            .padding(.top, 10)

            // ── Ruler ────────────────────────────────────────────────
            GeometryReader { geo in
                let cx = geo.size.width / 2

                ZStack(alignment: .top) {
                    // Tick canvas
                    Canvas { ctx, size in
                        for i in 0..<tickCount {
                            let offsetFromCenter = CGFloat(Double(i) - currentTickIndex) * tickSpacing
                            let x = cx + offsetFromCenter
                            guard x > -30 && x < size.width + 30 else { continue }

                            let isMajor = i % majorEvery == 0
                            let tickH: CGFloat = isMajor ? 28 : 15
                            let tickW: CGFloat = isMajor ? 2   : 1
                            let alpha: CGFloat = isMajor ? 0.45 : 0.22

                            var path = Path()
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: tickH))
                            ctx.stroke(path, with: .color(Color(.label).opacity(alpha)), lineWidth: tickW)

                            if isMajor {
                                let val = item.range.lowerBound + Double(i) * item.step
                                let lbl = item.decimals > 0
                                    ? String(format: "%.\(item.decimals)f", val)
                                    : "\(Int(val.rounded()))"
                                ctx.draw(
                                    Text(lbl)
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color(.secondaryLabel)),
                                    at: CGPoint(x: x, y: tickH + 4),
                                    anchor: .top
                                )
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: 56)

                    // Center pointer
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.primary)
                            .frame(width: 3, height: 40)
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 6, height: 6)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, -2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { val in
                            let deltaPts = val.translation.width - dragAccum
                            let deltaSteps = -deltaPts / tickSpacing
                            let newRaw = currentValue + deltaSteps * item.step
                            let snapped = (newRaw / item.step).rounded() * item.step
                            let precision = pow(10.0, Double(item.decimals))
                            let rounded = (snapped * precision).rounded() / precision
                            let clamped = min(max(rounded, item.range.lowerBound), item.range.upperBound)
                            if clamped != currentValue {
                                currentValue = clamped
                                HapticManager.selection()
                            }
                            dragAccum = val.translation.width
                        }
                        .onEnded { _ in dragAccum = 0 }
                )
            }
            .frame(height: 72)
            .padding(.top, 8)

            // ── Confirm ──────────────────────────────────────────────
            Button {
                onConfirm(currentValue)
                dismiss()
            } label: {
                Text("Confirm")
                    .font(.headline)
                    .foregroundStyle(Color(UIColor.systemBackground))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
    }
}

// MARK: - Vitals Requests

struct NurseVitalsRequestsView: View {
    let appState: AppState
    @Environment(DataStore.self) private var dataStore
    @State private var selectedPatientForVitals: NursePatientInfo?

    /// IDs of patients who are currently admitted
    private var admittedPatientIds: Set<String> {
        Set(dataStore.admissions.filter { $0.status == .admitted }.map(\.patientId))
    }
    private var pendingRequests: [VitalsRequest] {
        dataStore.vitalsRequests.filter { $0.status == .pending && admittedPatientIds.contains($0.patientId) }
            .sorted { $0.createdAt > $1.createdAt }
    }
    private var completedRequests: [VitalsRequest] {
        dataStore.vitalsRequests.filter { $0.status == .completed && admittedPatientIds.contains($0.patientId) }
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
    }

    var body: some View {
        List {
            Section {
                if pendingRequests.isEmpty {
                    Text("All Caught Up")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(pendingRequests) { request in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(patientName(for: request.patientId))
                                        .font(.headline)
                                        .foregroundStyle(Color.primary)
                                    Text("Requested by Dr. \(doctorName(for: request.doctorId))")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.secondary)
                                    Text(request.createdAt.relative)
                                        .font(.caption2)
                                        .foregroundStyle(Color.secondary)
                                }
                                Spacer()
                                
                                Button { recordVitalsForRequest(request) } label: {
                                    Text("Record")
                                        .font(.subheadline.weight(.medium))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color(.secondarySystemFill))
                                        .foregroundStyle(Color.primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: { Text("Pending Requests (\(pendingRequests.count))").textCase(.uppercase) }

            if !completedRequests.isEmpty {
                Section("Completed") {
                    ForEach(completedRequests.prefix(10)) { request in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(patientName(for: request.patientId))
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color.primary)
                                Text("Dr. \(doctorName(for: request.doctorId))")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Completed")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.secondary)
                                if let c = request.completedAt {
                                    Text(c.relative)
                                        .font(.caption2)
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Vitals Requests")
        .sheet(item: $selectedPatientForVitals) { info in
            NavigationStack { NurseVitalsFormView(patientInfo: info) }
        }
        .refreshable { await dataStore.refreshFromBackend() }
    }

    private func patientName(for patientId: String) -> String {
        if let p = dataStore.nursePatients.first(where: { $0.id == patientId || $0.userId == patientId }) { return p.personalInfo.fullName }
        return dataStore.admissions.first(where: { $0.patientId == patientId })?.patientName ?? "Patient"
    }
    private func doctorName(for doctorId: String) -> String {
        dataStore.doctors.first(where: { $0.id == doctorId || $0.userId == doctorId })?.name ?? "Unknown"
    }
    private func recordVitalsForRequest(_ request: VitalsRequest) {
        let assignment = dataStore.nurseAssignments.first(where: { $0.patientId == request.patientId })
            ?? NursePatientAssignment(staffId: request.nurseId, patientId: request.patientId)
        let patient = dataStore.nursePatients.first(where: { $0.id == request.patientId || $0.userId == request.patientId })
        let admission = dataStore.admissions.first(where: { $0.patientId == request.patientId && $0.status == .admitted })
        selectedPatientForVitals = NursePatientInfo(assignment: assignment, patient: patient, admission: admission,
                                                    latestVital: nil, displayName: patientName(for: request.patientId))
    }
}
