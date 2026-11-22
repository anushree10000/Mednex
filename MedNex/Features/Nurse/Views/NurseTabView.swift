//
//  NurseTabView.swift
//  MedNex
//
//  Nurse module — implements Doctor → Patient → Nurse → Doctor → Patient flow.
//  Nurse is assigned to assist doctors: receives check-in notifications,
//  records vitals before doctor sees patient, and manages bed availability.

import SwiftUI

struct NurseTabView: View {
    let appState: AppState
    @State private var selectedTab = 0
    @State private var showProfile = false
    @Environment(DataStore.self) private var dataStore
    
    private var newAlertCount: Int {
        dataStore.notifications.filter { !$0.isRead }.count
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "heart.text.clipboard.fill", value: 0) {
                NavigationStack {
                    NurseDashboardView(appState: appState, showProfile: $showProfile)
                }
            }
            
            Tab("Patients", systemImage: "person.2.fill", value: 1) {
                NavigationStack {
                    NursePatientQueueView()
                }
            }
            .badge(newAlertCount)
            
            Tab("Vitals", systemImage: "waveform.path.ecg", value: 2) {
                NavigationStack {
                    NurseVitalsEntryView()
                }
            }
            
            Tab("Beds", systemImage: "bed.double.fill", value: 3) {
                NavigationStack {
                    NurseBedUpdateView()
                }
            }
            
            Tab("Tasks", systemImage: "checklist", value: 4) {
                NavigationStack {
                    NurseTasksView()
                }
            }
        }
        .tint(MedNexTheme.Colors.primary)
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                StaffProfileView(appState: appState)
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

// MARK: - Nurse Dashboard (enhanced)
struct NurseDashboardView: View {
    let appState: AppState
    @Binding var showProfile: Bool
    @State private var animateCards = false
    @Environment(DataStore.self) private var dataStore
    
    private var vitals: [VitalRecord] { dataStore.vitalRecords }
    
    private var waitingCount: Int {
        dataStore.appointments.filter { appt in
            Calendar.current.isDateInToday(appt.dateTime) && appt.status == .scheduled
        }.count
    }
    
    private var assignedDoctor: Doctor? {
        dataStore.doctors.first
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Hi, \(appState.currentUser?.displayName ?? "Nurse")")
                            .font(MedNexTheme.Typography.title2)
                        Text("Nursing Station" + (assignedDoctor != nil ? " — Assigned to Dr. \(assignedDoctor!.name)" : ""))
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Button { showProfile = true } label: {
                        AvatarView(name: appState.currentUser?.displayName ?? "N", size: 48, backgroundColor: MedNexTheme.Colors.nurseTint)
                    }
                }
                .opacity(animateCards ? 1 : 0)
                
                // Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                    StatCard(title: "Patients Waiting", value: "\(waitingCount)", icon: "person.2.fill", tintColor: MedNexTheme.Colors.warning)
                    StatCard(title: "Vitals Recorded", value: "\(vitals.count)", icon: "waveform.path.ecg", tintColor: MedNexTheme.Colors.success)
                    StatCard(title: "Beds to Update", value: "\(dataStore.beds.filter { $0.status != .available && $0.status != .occupied }.count)", icon: "bed.double.fill", tintColor: MedNexTheme.Colors.info)
                    StatCard(title: "Alerts", value: "\(dataStore.notifications.filter { !$0.isRead }.count)", icon: "exclamationmark.triangle.fill", tintColor: MedNexTheme.Colors.error)
                }
                .opacity(animateCards ? 1 : 0)
                
                // Doctor Assignment Info
                if let doctor = assignedDoctor {
                    GlassCard {
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                            Label("Assigned Doctor", systemImage: "stethoscope")
                                .font(MedNexTheme.Typography.headline)
                                .foregroundStyle(MedNexTheme.Colors.primary)
                            
                            HStack(spacing: MedNexTheme.Spacing.md) {
                                AvatarView(name: "Dr. \(doctor.name)", size: 44, backgroundColor: MedNexTheme.Colors.doctorTint)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Dr. \(doctor.name)")
                                        .font(MedNexTheme.Typography.headline)
                                    Text("\(doctor.specialty.rawValue) — \(doctor.departmentId ?? "N/A")")
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                }
                                Spacer()
                                StatusBadge(text: "Active", color: MedNexTheme.Colors.success)
                            }
                        }
                    }
                    .opacity(animateCards ? 1 : 0)
                }
                
                // Active Notifications
                SectionHeader(title: "Recent Alerts")
                
                let recentNotifs = dataStore.notifications.sorted(by: { $0.createdAt > $1.createdAt }).prefix(3)
                if recentNotifs.isEmpty {
                    GlassCard(padding: MedNexTheme.Spacing.sm) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(MedNexTheme.Colors.success)
                            Text("No recent alerts")
                                .font(MedNexTheme.Typography.subheadline)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                    }
                } else {
                    ForEach(Array(recentNotifs)) { notif in
                        notificationCard(
                            icon: notificationIcon(notif.type),
                            title: notif.title,
                            message: notif.body,
                            time: notif.createdAt.relative,
                            priority: notif.isRead ? .low : .high
                        )
                    }
                }
                
                // Recent Vitals
                SectionHeader(title: "Recent Vitals Recorded")
                
                ForEach(vitals.prefix(3)) { vital in
                    GlassCard(padding: MedNexTheme.Spacing.sm) {
                        HStack(spacing: MedNexTheme.Spacing.md) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vital.timestamp.shortDate)
                                    .font(MedNexTheme.Typography.caption.weight(.semibold))
                                Text(vital.timestamp.timeOnly)
                                    .font(MedNexTheme.Typography.caption2)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                            Spacer()
                            if let hr = vital.heartRateFormatted {
                                miniVital(icon: "heart.fill", value: hr, color: MedNexTheme.Colors.error)
                            }
                            if let bp = vital.bloodPressureFormatted {
                                miniVital(icon: "waveform.path.ecg", value: bp, color: MedNexTheme.Colors.info)
                            }
                            if let spo2 = vital.spO2Formatted {
                                miniVital(icon: "lungs.fill", value: spo2, color: MedNexTheme.Colors.primary)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Dashboard")
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
    }
    
    private func miniVital(icon: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).foregroundStyle(color).font(.caption)
            Text(value).font(MedNexTheme.Typography.caption2.weight(.medium))
        }
    }
    
    private func notificationCard(icon: String, title: String, message: String, time: String, priority: AlertPriority) -> some View {
        GlassCard(padding: MedNexTheme.Spacing.sm) {
            HStack(spacing: MedNexTheme.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(priority.color)
                    .frame(width: 36, height: 36)
                    .background(priority.color.opacity(0.12), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MedNexTheme.Typography.subheadline.weight(.semibold))
                    Text(message)
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                Text(time)
                    .font(MedNexTheme.Typography.caption2)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
        }
    }
    
    private func notificationIcon(_ type: NotificationType) -> String {
        switch type {
        case .appointmentBooked: return "calendar.badge.plus"
        case .appointmentReminder: return "calendar.badge.clock"
        case .appointmentCancelled: return "calendar.badge.minus"
        case .prescriptionReady: return "pills.fill"
        case .labResultReady: return "flask.fill"
        case .paymentDue: return "creditcard.fill"
        case .shiftAssigned: return "clock.fill"
        case .general: return "bell.fill"
        }
    }
}

private enum AlertPriority {
    case high, medium, low
    var color: Color {
        switch self {
        case .high: return MedNexTheme.Colors.error
        case .medium: return MedNexTheme.Colors.warning
        case .low: return MedNexTheme.Colors.info
        }
    }
}

// MARK: - Patient Queue (Doctor → Patient → NURSE → Doctor → Patient)
struct NursePatientQueueView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var localStatuses: [String: PatientQueueStatus] = [:]
    
    /// Derive queue from today's appointments
    private var queuePatients: [NurseQueuePatient] {
        let todayAppts = dataStore.appointments.filter { Calendar.current.isDateInToday($0.dateTime) }
            .sorted { $0.dateTime < $1.dateTime }
        let doctorName = dataStore.doctors.first.map { "Dr. \($0.name)" } ?? "Doctor"
        return todayAppts.map { appt in
            let status = localStatuses[appt.id] ?? mapAppointmentStatus(appt.status)
            return NurseQueuePatient(
                id: appt.id,
                name: appt.patientName,
                doctor: doctorName,
                time: appt.dateTime.timeOnly,
                room: "—",
                status: status,
                reason: appt.type.displayName
            )
        }
    }
    
    private func mapAppointmentStatus(_ status: AppointmentStatus) -> PatientQueueStatus {
        switch status {
        case .scheduled: return .checkedIn
        case .inProgress: return .vitalsPending
        case .completed: return .done
        case .cancelled: return .done
        case .noShow: return .done
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.md) {
                // Flow explainer
                GlassCard(padding: MedNexTheme.Spacing.sm) {
                    HStack(spacing: MedNexTheme.Spacing.xs) {
                        flowStep("Check-in", icon: "person.badge.clock.fill", active: true)
                        Image(systemName: "arrow.right").font(.caption2).foregroundStyle(MedNexTheme.Colors.textTertiary)
                        flowStep("Vitals", icon: "waveform.path.ecg", active: true)
                        Image(systemName: "arrow.right").font(.caption2).foregroundStyle(MedNexTheme.Colors.textTertiary)
                        flowStep("Doctor", icon: "stethoscope", active: false)
                        Image(systemName: "arrow.right").font(.caption2).foregroundStyle(MedNexTheme.Colors.textTertiary)
                        flowStep("Done", icon: "checkmark.circle.fill", active: false)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Queue
                if queuePatients.isEmpty {
                    EmptyStateView(icon: "person.2", title: "No Patients Today", message: "Today's appointments will appear here.")
                        .padding(.top, MedNexTheme.Spacing.xxl)
                }
                
                ForEach(queuePatients) { patient in
                    GlassCard {
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                            HStack {
                                AvatarView(name: patient.name, size: 40, backgroundColor: patient.status.color)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(patient.name)
                                        .font(MedNexTheme.Typography.headline)
                                    Text(patient.reason)
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                StatusBadge(text: patient.status.displayName, color: patient.status.color)
                            }
                            
                            HStack(spacing: MedNexTheme.Spacing.lg) {
                                Label(patient.time, systemImage: "clock")
                                Label("Room \(patient.room)", systemImage: "door.left.hand.open")
                                Label(patient.doctor, systemImage: "stethoscope")
                            }
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            
                            // Action buttons based on status
                            if patient.status == .checkedIn || patient.status == .vitalsPending {
                                NavigationLink {
                                    NurseVitalsEntryView()
                                        .onDisappear {
                                            withAnimation { localStatuses[patient.id] = .vitalsComplete }
                                        }
                                } label: {
                                    Label("Record Vitals", systemImage: "waveform.path.ecg")
                                        .font(MedNexTheme.Typography.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, MedNexTheme.Spacing.xs)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(MedNexTheme.Colors.primary)
                            } else if patient.status == .vitalsComplete {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(MedNexTheme.Colors.success)
                                    Text("Vitals recorded — waiting for doctor")
                                        .font(MedNexTheme.Typography.caption)
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
        .navigationTitle("Patient Queue")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
    }
    
    private func flowStep(_ title: String, icon: String, active: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(active ? MedNexTheme.Colors.primary : MedNexTheme.Colors.textTertiary)
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(active ? MedNexTheme.Colors.textPrimary : MedNexTheme.Colors.textTertiary)
        }
    }
}

// MARK: - Nurse Vitals Entry (enhanced with patient selector)
struct NurseVitalsEntryView: View {
    @State private var selectedPatientId = ""
    @State private var heartRate = ""
    @State private var systolic = ""
    @State private var diastolic = ""
    @State private var temperature = ""
    @State private var oxygenSat = ""
    @State private var weight = ""
    @State private var showSaved = false
    @State private var showAbnormal = false
    @Environment(DataStore.self) private var dataStore
    
    /// Unique patients from appointments
    private var patients: [(id: String, name: String)] {
        let grouped = Dictionary(grouping: dataStore.appointments, by: \.patientId)
        return grouped.compactMap { (patientId, appointments) in
            guard let latest = appointments.sorted(by: { $0.dateTime > $1.dateTime }).first else { return nil }
            return (id: patientId, name: latest.patientName)
        }
        .sorted { $0.name < $1.name }
    }
    
    private var selectedPatientName: String {
        patients.first(where: { $0.id == selectedPatientId })?.name ?? ""
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Patient selector
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        Label("Select Patient", systemImage: "person.fill")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        Menu {
                            ForEach(patients, id: \.id) { p in
                                Button(p.name) { selectedPatientId = p.id }
                            }
                        } label: {
                            HStack {
                                Text(selectedPatientName.isEmpty ? "Select patient..." : selectedPatientName)
                                    .foregroundStyle(selectedPatientName.isEmpty ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                            .padding(MedNexTheme.Spacing.sm)
                            .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                        }
                    }
                }
                
                // Vitals form
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        Label("Record Vitals" + (selectedPatientName.isEmpty ? "" : " for \(selectedPatientName)"), systemImage: "waveform.path.ecg")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        vitalField("Heart Rate (bpm)", text: $heartRate, icon: "heart.fill", normalRange: "60–100")
                        HStack {
                            vitalField("Systolic", text: $systolic, icon: "arrow.up", normalRange: "90–120")
                            vitalField("Diastolic", text: $diastolic, icon: "arrow.down", normalRange: "60–80")
                        }
                        vitalField("Temperature (°F)", text: $temperature, icon: "thermometer.medium", normalRange: "97–99")
                        vitalField("SpO₂ (%)", text: $oxygenSat, icon: "lungs.fill", normalRange: "95–100")
                        vitalField("Weight (kg)", text: $weight, icon: "scalemass.fill", normalRange: "—")
                    }
                }
                
                // Abnormal warning
                if isAnyVitalAbnormal {
                    GlassCard(padding: MedNexTheme.Spacing.sm) {
                        HStack(spacing: MedNexTheme.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(MedNexTheme.Colors.error)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Abnormal Values Detected")
                                    .font(MedNexTheme.Typography.subheadline.weight(.semibold))
                                    .foregroundStyle(MedNexTheme.Colors.error)
                                Text("Doctor will be notified immediately upon saving.")
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                        }
                    }
                }
                
                // Save button
                Button {
                    HapticManager.success()
                    saveVitals()
                    showSaved = true
                } label: {
                    Text("Save & Notify Doctor")
                }
                .buttonStyle(.medNexPrimary)
                .disabled((heartRate.isEmpty && systolic.isEmpty) || selectedPatientId.isEmpty)
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Record Vitals")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .alert("Vitals Saved!", isPresented: $showSaved) {
            Button("OK") {
                heartRate = ""; systolic = ""; diastolic = ""
                temperature = ""; oxygenSat = ""; weight = ""
            }
        } message: {
            Text("Vitals for \(selectedPatientName) recorded." + (dataStore.doctors.first != nil ? " Dr. \(dataStore.doctors.first!.name) has been notified." : ""))
        }
    }
    
    private func saveVitals() {
        let record = VitalRecord(
            patientId: selectedPatientId,
            recordedBy: "Nurse",
            bloodPressureSystolic: Double(systolic),
            bloodPressureDiastolic: Double(diastolic),
            heartRate: Double(heartRate),
            temperature: Double(temperature),
            oxygenSaturation: Double(oxygenSat),
            weight: Double(weight)
        )
        dataStore.addVitalRecord(record)
        
        // Notify doctor if abnormal
        if isAnyVitalAbnormal {
            dataStore.addNotification(
                title: "⚠️ Abnormal Vitals",
                message: "Abnormal vitals detected for \(selectedPatientName). Immediate review recommended.",
                type: .labResultReady
            )
        }
    }
    
    private var isAnyVitalAbnormal: Bool {
        if let hr = Double(heartRate), (hr < 60 || hr > 100) { return true }
        if let sys = Double(systolic), (sys < 90 || sys > 140) { return true }
        if let temp = Double(temperature), (temp < 97 || temp > 99.5) { return true }
        if let spo2 = Double(oxygenSat), spo2 < 95 { return true }
        return false
    }
    
    private func vitalField(_ placeholder: String, text: Binding<String>, icon: String, normalRange: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: icon).foregroundStyle(MedNexTheme.Colors.primary).frame(width: 24)
                TextField(placeholder, text: text)
                    .keyboardType(.decimalPad)
            }
            .padding(MedNexTheme.Spacing.sm)
            .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
            
            Text("Normal: \(normalRange)")
                .font(.system(size: 10))
                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                .padding(.leading, 32)
        }
    }
}

// MARK: - Nurse Bed Updates (nurse controls bed availability)
struct NurseBedUpdateView: View {
    @Environment(DataStore.self) private var dataStore
    
    /// Map DataStore beds into NurseBedItem for the nurse UI
    private var beds: [NurseBedItem] {
        dataStore.beds.map { bed in
            NurseBedItem(
                datastoreId: bed.id,
                number: bed.bedNumber,
                ward: bed.ward,
                status: mapBedStatus(bed.status),
                patient: bed.patientName
            )
        }
    }
    
    private func mapBedStatus(_ status: BedStatus) -> NurseBedStatus {
        switch status {
        case .available: return .available
        case .occupied: return .occupied
        case .cleaning: return .cleaning
        case .reserved: return .discharged
        case .maintenance: return .cleaning
        }
    }
    
    @State private var selectedFilter = 0
    private let filters = ["All", "Needs Action", "Occupied", "Available"]
    
    var filteredBeds: [NurseBedItem] {
        switch selectedFilter {
        case 1: return beds.filter { $0.status == .cleaning || $0.status == .discharged }
        case 2: return beds.filter { $0.status == .occupied }
        case 3: return beds.filter { $0.status == .available }
        default: return beds
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.md) {
                // Summary
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                    miniStat(title: "Needs Action", count: beds.filter { $0.status == .cleaning || $0.status == .discharged }.count, color: MedNexTheme.Colors.warning)
                    miniStat(title: "Occupied", count: beds.filter { $0.status == .occupied }.count, color: MedNexTheme.Colors.info)
                    miniStat(title: "Available", count: beds.filter { $0.status == .available }.count, color: MedNexTheme.Colors.success)
                }
                
                // Filter
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(filters.indices, id: \.self) { i in
                        Text(filters[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)
                
                // Bed list
                ForEach(Array(filteredBeds.enumerated()), id: \.element.id) { _, bed in
                    GlassCard {
                        HStack(spacing: MedNexTheme.Spacing.md) {
                            Image(systemName: bed.status.icon)
                                .font(.title2)
                                .foregroundStyle(bed.status.color)
                                .frame(width: 44, height: 44)
                                .background(bed.status.color.opacity(0.12), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bed \(bed.number)")
                                    .font(MedNexTheme.Typography.headline)
                                Text(bed.ward)
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                if let patient = bed.patient {
                                    Text(patient)
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                }
                            }
                            
                            Spacer()
                            
                            // Action buttons for nurse
                            if bed.status == .discharged {
                                Button {
                                    HapticManager.medium()
                                    dataStore.updateBedStatus(
                                        bed.datastoreId ?? "",
                                        status: .cleaning,
                                        patientName: nil
                                    )
                                    dataStore.addNotification(
                                        title: "Bed Cleaning Started",
                                        message: "Bed \(bed.number) in \(bed.ward) is now being cleaned.",
                                        type: .general
                                    )
                                } label: {
                                    Label("Start Clean", systemImage: "sparkles")
                                        .font(MedNexTheme.Typography.caption.weight(.semibold))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(MedNexTheme.Colors.warning)
                            } else if bed.status == .cleaning {
                                Button {
                                    HapticManager.success()
                                    dataStore.updateBedStatus(
                                        bed.datastoreId ?? "",
                                        status: .available,
                                        patientName: nil
                                    )
                                    dataStore.addNotification(
                                        title: "Bed Ready",
                                        message: "Bed \(bed.number) in \(bed.ward) is now clean and available.",
                                        type: .general
                                    )
                                } label: {
                                    Label("Mark Ready", systemImage: "checkmark.circle.fill")
                                        .font(MedNexTheme.Typography.caption.weight(.semibold))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(MedNexTheme.Colors.success)
                            } else {
                                StatusBadge(text: bed.status.displayName, color: bed.status.color)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Bed Management")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
    }
    
    private func miniStat(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(MedNexTheme.Typography.caption2)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MedNexTheme.Spacing.sm)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md))
    }
}

// MARK: - Nurse Tasks (unchanged from original with minor polish)
struct NurseTasksView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var taskCompletions: [String: Bool] = [:]
    
    /// Generate tasks from today's appointments and beds needing attention
    private var tasks: [(id: String, title: String)] {
        var items: [(id: String, title: String)] = []
        
        // Tasks from today's appointments
        for appt in dataStore.appointments.filter({ Calendar.current.isDateInToday($0.dateTime) }).prefix(4) {
            items.append((id: "appt-\(appt.id)", title: "Take vitals — \(appt.patientName) (\(appt.type.displayName))"))
        }
        
        // Tasks from beds needing action
        for bed in dataStore.beds.filter({ $0.status == .cleaning || $0.status == .maintenance }).prefix(2) {
            items.append((id: "bed-\(bed.id)", title: "Update bed \(bed.bedNumber) status after cleaning"))
        }
        
        // Generic nursing tasks
        if items.count < 3 {
            items.append((id: "generic-1", title: "Check medication schedules for assigned patients"))
            items.append((id: "generic-2", title: "Review pending lab results and notify doctors"))
        }
        
        return items
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: MedNexTheme.Spacing.sm) {
                // Progress
                GlassCard(padding: MedNexTheme.Spacing.sm) {
                    HStack {
                        Text("\(tasks.filter { taskCompletions[$0.id] == true }.count)/\(tasks.count) completed")
                            .font(MedNexTheme.Typography.subheadline.weight(.medium))
                        Spacer()
                        ProgressView(value: Double(tasks.filter { taskCompletions[$0.id] == true }.count), total: Double(max(tasks.count, 1)))
                            .tint(MedNexTheme.Colors.success)
                            .frame(width: 100)
                    }
                }
                
                ForEach(tasks, id: \.id) { task in
                    let isCompleted = taskCompletions[task.id] == true
                    GlassCard(padding: MedNexTheme.Spacing.sm) {
                        HStack(spacing: MedNexTheme.Spacing.sm) {
                            Button {
                                HapticManager.selection()
                                withAnimation { taskCompletions[task.id] = !(taskCompletions[task.id] ?? false) }
                            } label: {
                                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isCompleted ? MedNexTheme.Colors.success : MedNexTheme.Colors.textTertiary)
                                    .font(.title3)
                            }
                            
                            Text(task.title)
                                .font(MedNexTheme.Typography.subheadline)
                                .strikethrough(isCompleted)
                                .foregroundStyle(isCompleted ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.textPrimary)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Tasks")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
    }
}

// MARK: - Helper Models

struct NurseQueuePatient: Identifiable {
    let id: String
    let name: String
    let doctor: String
    let time: String
    let room: String
    var status: PatientQueueStatus
    let reason: String
}

enum PatientQueueStatus {
    case upcoming, checkedIn, vitalsPending, vitalsComplete, withDoctor, done
    
    var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .checkedIn: return "Checked In"
        case .vitalsPending: return "Vitals Pending"
        case .vitalsComplete: return "Vitals Done"
        case .withDoctor: return "With Doctor"
        case .done: return "Complete"
        }
    }
    
    var color: Color {
        switch self {
        case .upcoming: return MedNexTheme.Colors.textTertiary
        case .checkedIn: return MedNexTheme.Colors.warning
        case .vitalsPending: return MedNexTheme.Colors.error
        case .vitalsComplete: return MedNexTheme.Colors.success
        case .withDoctor: return MedNexTheme.Colors.primary
        case .done: return MedNexTheme.Colors.success
        }
    }
}

struct NurseBedItem: Identifiable {
    let id = UUID()
    let datastoreId: String?
    let number: String
    let ward: String
    var status: NurseBedStatus
    let patient: String?
}

enum NurseBedStatus {
    case available, occupied, cleaning, discharged
    
    var displayName: String {
        switch self {
        case .available: return "Available"
        case .occupied: return "Occupied"
        case .cleaning: return "Cleaning"
        case .discharged: return "Discharged"
        }
    }
    
    var color: Color {
        switch self {
        case .available: return MedNexTheme.Colors.success
        case .occupied: return MedNexTheme.Colors.info
        case .cleaning: return MedNexTheme.Colors.warning
        case .discharged: return MedNexTheme.Colors.error
        }
    }
    
    var icon: String {
        switch self {
        case .available: return "bed.double"
        case .occupied: return "bed.double.fill"
        case .cleaning: return "sparkles"
        case .discharged: return "arrow.right.circle.fill"
        }
    }
}
