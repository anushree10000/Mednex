import SwiftUI

struct PatientMedicalHistoryView: View {
    let appState: AppState
    let patientId: String
    let patientName: String
    
    @State private var selectedTab = 0
    @State private var patientProfile: Patient?
    @State private var isLoading = true
    @Environment(DataStore.self) private var dataStore
    
    private var patientPrescriptions: [Prescription] {
        dataStore.prescriptions.filter { $0.patientId == patientId }
    }
    
    private var groupedPrescriptions: [(Date, [Prescription])] {
        let grouped = Dictionary(grouping: patientPrescriptions) { prescription in
            Calendar.current.startOfDay(for: prescription.createdAt)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented Control
            Picker("History Tabs", selection: $selectedTab) {
                Text("History").tag(0)
                Text("Prescriptions").tag(1)
                Text("Timeline").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(MedNexTheme.Spacing.md)
            .background(Color(uiColor: .systemBackground))
            
            ScrollView {
                VStack(spacing: MedNexTheme.Spacing.lg) {
                    if isLoading {
                        ProgressView("Loading patient details...")
                            .padding(.top, MedNexTheme.Spacing.xl)
                    } else {
                        switch selectedTab {
                        case 0:
                            medicalHistoryTab
                        case 1:
                            pastPrescriptionsTab
                        case 2:
                            timelineTab
                        default:
                            EmptyView()
                        }
                    }
                }
                .padding(.vertical, MedNexTheme.Spacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .doctorFlowBackground()
        .task {
            await fetchPatientProfile()
        }
    }
    
    // MARK: - App State / Fetch
    
    private func fetchPatientProfile() async {
        isLoading = true
        #if canImport(Supabase)
        let repo = PatientRepository.shared
        do {
            let patient = try await repo.fetchPatient(byUserId: patientId)
            await MainActor.run {
                self.patientProfile = patient
                self.isLoading = false
            }
            return
        } catch {
            do {
                let patient: Patient = try await SupabaseService.shared.fetchSingle(from: "patients", id: patientId)
                await MainActor.run {
                    self.patientProfile = patient
                    self.isLoading = false
                }
                return
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
        #else
        isLoading = false
        #endif
    }
    
    // MARK: - Tab 0: Medical History
    
    private var patientVitals: [VitalRecord] {
        dataStore.vitalRecords
            .filter { $0.patientId == patientId }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    private var patientLabTests: [LabTest] {
        dataStore.labTests.filter { $0.patientId == patientId }
    }
    
    private var medicalHistoryTab: some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.lg) {
            if let patient = patientProfile {
                DoctorCard {
                    VStack(spacing: MedNexTheme.Spacing.md) {
                        patientDetailRow(icon: "person.text.rectangle", title: "Age / Sex",
                            value: "\(patient.personalInfo.age) yrs, \(patient.personalInfo.gender.displayName)")
                        Divider()
                        patientDetailRow(icon: "drop.fill", title: "Blood Group",
                            value: patient.medicalInfo.bloodType.rawValue, iconColor: .red)
                        if !patient.medicalInfo.allergies.isEmpty {
                            Divider()
                            patientDetailRow(icon: "allergens", title: "Allergies",
                                value: patient.medicalInfo.allergies.joined(separator: ", "), iconColor: .orange)
                        }
                        if !patient.medicalInfo.chronicConditions.isEmpty {
                            Divider()
                            patientDetailRow(icon: "heart.text.clipboard", title: "Conditions",
                                value: patient.medicalInfo.chronicConditions.joined(separator: ", "),
                                iconColor: MedNexTheme.Colors.warning)
                        }
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
            }
            
            // Vitals
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                SectionHeader(title: "Recent Vitals")
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                
                if patientVitals.isEmpty {
                    DoctorCard {
                        Label("No vitals recorded.", systemImage: "waveform.path.ecg")
                            .font(MedNexTheme.Typography.body)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                    }.padding(.horizontal, MedNexTheme.Spacing.md)
                } else {
                    ForEach(patientVitals.prefix(3)) { vital in
                        DoctorCard(padding: MedNexTheme.Spacing.sm) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(vital.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(MedNexTheme.Typography.caption.weight(.semibold))
                                HStack(spacing: MedNexTheme.Spacing.md) {
                                    if let hr = vital.heartRateFormatted { miniVital(icon: "heart.fill", value: hr, color: MedNexTheme.Colors.error) }
                                    if let bp = vital.bloodPressureFormatted { miniVital(icon: "waveform.path.ecg", value: bp, color: MedNexTheme.Colors.info) }
                                    if let spo2 = vital.spO2Formatted { miniVital(icon: "lungs.fill", value: spo2, color: MedNexTheme.Colors.primary) }
                                    if let temp = vital.temperatureFormatted { miniVital(icon: "thermometer.medium", value: temp, color: .orange) }
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
                    SectionHeader(title: "Recent Lab Tests")
                        .padding(.horizontal, MedNexTheme.Spacing.md)
                    
                    ForEach(patientLabTests.prefix(3)) { test in
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
        }
    }
    
    // MARK: - Tab 1: Past Prescriptions
    
    @State private var expandedDates: Set<Date> = []
    
    private var pastPrescriptionsTab: some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            if groupedPrescriptions.isEmpty {
                DoctorCard {
                    Label("No past prescriptions.", systemImage: "pills.fill")
                        .font(MedNexTheme.Typography.body)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }.padding(.horizontal, MedNexTheme.Spacing.md)
            } else {
                ForEach(groupedPrescriptions, id: \.0) { date, prescriptions in
                    DoctorCard(padding: MedNexTheme.Spacing.sm) {
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedDates.contains(date) },
                                set: { isExpanded in
                                    if isExpanded {
                                        expandedDates.insert(date)
                                    } else {
                                        expandedDates.remove(date)
                                    }
                                }
                            )
                        ) {
                            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                                ForEach(prescriptions) { rx in
                                    NavigationLink {
                                        DoctorPrescriptionDetailView(prescription: rx)
                                    } label: {
                                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                                            HStack {
                                                Text(rx.diagnosis.isEmpty ? "Prescription" : rx.diagnosis)
                                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                                    .foregroundStyle(MedNexTheme.Colors.primary)
                                                Spacer()
                                                StatusBadge(text: rx.status.displayName, color: Color(hex: rx.status.color))
                                            }
                                            
                                            ForEach(rx.medicines) { med in
                                                HStack {
                                                    Image(systemName: "pill.fill")
                                                        .foregroundColor(MedNexTheme.Colors.textTertiary)
                                                        .font(.caption)
                                                    Text(med.name)
                                                        .font(MedNexTheme.Typography.body)
                                                    Spacer()
                                                    Text("\(med.dosage) - \(med.frequency.rawValue)")
                                                        .font(MedNexTheme.Typography.caption)
                                                        .foregroundColor(MedNexTheme.Colors.textSecondary)
                                                }
                                            }
                                            if !rx.notes.isEmpty {
                                                Text("Notes: \(rx.notes)")
                                                    .font(MedNexTheme.Typography.caption2)
                                                    .foregroundColor(MedNexTheme.Colors.textSecondary)
                                                    .italic()
                                            }
                                        }
                                        .padding(.top, MedNexTheme.Spacing.sm)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if rx.id != prescriptions.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.top, MedNexTheme.Spacing.sm)
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(MedNexTheme.Colors.primary)
                                Text(date.formatted(date: .long, time: .omitted))
                                    .font(MedNexTheme.Typography.headline)
                                    .foregroundColor(MedNexTheme.Colors.textPrimary)
                                Spacer()
                                Text("\(prescriptions.count) Rx")
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundColor(MedNexTheme.Colors.textTertiary)
                                    .padding(.trailing, 8)
                            }
                        }
                        .tint(MedNexTheme.Colors.primary)
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                }
            }
        }
    }
    
    // MARK: - Tab 2: Timeline
    
    private var timelineTab: some View {
        let items = buildTimelineItems()
        return VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            if items.isEmpty {
                DoctorCard {
                    VStack(spacing: MedNexTheme.Spacing.sm) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.largeTitle)
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        Text("No medical history yet")
                            .font(MedNexTheme.Typography.body)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MedNexTheme.Spacing.lg)
                }
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    timelineCard(item, isLast: index == items.count - 1)
                }
            }
        }
        .padding(.horizontal, MedNexTheme.Spacing.md)
    }
    
    // MARK: - Helpers
    
    private func patientDetailRow(icon: String, title: String, value: String, iconColor: Color = MedNexTheme.Colors.textSecondary) -> some View {
        HStack(spacing: MedNexTheme.Spacing.md) {
            Text(title).font(MedNexTheme.Typography.body).foregroundColor(MedNexTheme.Colors.textSecondary)
            Spacer()
            Text(value).font(.system(.body, design: .rounded, weight: .medium)).foregroundColor(MedNexTheme.Colors.textPrimary)
        }
    }
    
    private func miniVital(icon: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).foregroundStyle(color).font(.caption)
            Text(value).font(MedNexTheme.Typography.caption2.weight(.medium))
        }
    }
    
    private func buildTimelineItems() -> [DoctorTimelineItem] {
        var items: [DoctorTimelineItem] = []
        
        for appt in dataStore.appointments.filter({ $0.patientId == patientId }) {
            items.append(DoctorTimelineItem(
                date: appt.dateTime, type: .visit,
                title: appt.type.displayName, subtitle: "Dr. \(appt.doctorName)",
                detail: appt.notes.isEmpty ? nil : appt.notes,
                rating: appt.rating, review: appt.review,
                status: appt.status.displayName,
                statusColor: Color(hex: appt.status.color)
            ))
        }
        
        for rx in dataStore.prescriptions.filter({ $0.patientId == patientId }) {
            let medsText = rx.medicines.map { "\($0.name) \($0.dosage) — \($0.frequency.rawValue)" }.joined(separator: "\n")
            items.append(DoctorTimelineItem(
                date: rx.createdAt, type: .prescription,
                title: rx.diagnosis.isEmpty ? "Prescription" : rx.diagnosis,
                subtitle: "\(rx.medicines.count) medication\(rx.medicines.count == 1 ? "" : "s")",
                detail: medsText, notes: rx.notes
            ))
        }
        
        for lab in dataStore.labTests.filter({ $0.patientId == patientId }) {
            let resultsText = lab.results.map { "\($0.parameterName): \($0.value) \($0.unit)" }.joined(separator: "\n")
            items.append(DoctorTimelineItem(
                date: lab.completedAt ?? lab.orderedAt, type: .labResult,
                title: lab.testName, subtitle: lab.testCategory.rawValue,
                detail: resultsText.isEmpty ? nil : resultsText,
                status: lab.status.displayName, statusColor: labStatusColor(lab.status),
                abnormalCount: lab.results.filter { $0.isAbnormal }.count
            ))
        }
        
        return items.sorted { $0.date > $1.date }
    }
    
    private func timelineCard(_ item: DoctorTimelineItem, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: MedNexTheme.Spacing.sm) {
            VStack(spacing: 0) {
                Circle().fill(item.type.color).frame(width: 12, height: 12)
                if !isLast {
                    Rectangle().fill(MedNexTheme.Colors.textTertiary.opacity(0.3)).frame(width: 2).frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.date.medicalFormat)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                
                DoctorCard(padding: MedNexTheme.Spacing.sm) {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                        HStack {
                            Image(systemName: item.type.icon)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(item.type.color)
                                .frame(width: 26, height: 26)
                                .background(item.type.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title).font(.system(.subheadline, design: .rounded, weight: .semibold)).foregroundStyle(MedNexTheme.Colors.textPrimary)
                                Text(item.subtitle).font(MedNexTheme.Typography.caption).foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                            Spacer()
                            if let status = item.status, let color = item.statusColor {
                                StatusBadge(text: status, color: color)
                            }
                        }
                        
                        if let detail = item.detail, !detail.isEmpty {
                            Divider()
                            Text(detail).font(MedNexTheme.Typography.caption).foregroundStyle(MedNexTheme.Colors.textSecondary).lineLimit(4)
                        }
                        
                        if let notes = item.notes, !notes.isEmpty {
                            Text(notes).font(MedNexTheme.Typography.caption).foregroundStyle(MedNexTheme.Colors.textTertiary).italic().lineLimit(2)
                        }
                        
                        if let abnormal = item.abnormalCount, abnormal > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10))
                                Text("\(abnormal) abnormal value\(abnormal == 1 ? "" : "s")").font(.system(.caption2, design: .rounded, weight: .medium))
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }
    
    private func labStatusColor(_ status: LabTestStatus) -> Color {
        switch status {
        case .completed: return MedNexTheme.Colors.success
        case .pending: return MedNexTheme.Colors.warning
        case .processing: return MedNexTheme.Colors.info
        case .received: return MedNexTheme.Colors.primary
        case .cancelled: return MedNexTheme.Colors.error
        }
    }
}
