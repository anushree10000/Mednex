//
//  DoctorDashboardView.swift
//  MedNex
//

import SwiftUI

struct DoctorDashboardView: View {
    let appState: AppState
    @Binding var showProfile: Bool
    @Binding var selectedTab: Int
    @Binding var scheduleFilter: String
    @State private var animateCards = false
    @State private var showTodaysPatients = false
    @State private var selectedAppointment: Appointment?
    @Environment(DataStore.self) private var dataStore
    
    private var doctorId: String {
        appState.currentUser?.id ?? ""
    }
    
    /// All possible IDs this doctor could be referenced by in appointments
    private var myDoctorIds: Set<String> {
        var ids: Set<String> = [doctorId]
        // Also include the doctor table row ID if it differs from the auth UID
        if let doc = dataStore.doctors.first(where: { $0.userId == doctorId }) {
            ids.insert(doc.id)
        }
        return ids
    }
    
    private var todayAppointments: [Appointment] {
        dataStore.normalizedAppointmentsForDisplay.filter {
            Calendar.current.isDateInToday($0.dateTime) && myDoctorIds.contains($0.doctorId)
        }
    }
    
    // MARK: - Time-Based Greeting
    private func timeBasedGreeting() -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good morning,"
        case 12..<17:
            return "Good afternoon,"
        case 17..<21:
            return "Good evening,"
        default:
            return "Good night,"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Welcome
                HStack {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                        Text("Welcome back,")
                            .font(MedNexTheme.Typography.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        Text(appState.currentUser?.displayName ?? "Doctor")
                            .font(MedNexTheme.Typography.title2)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, MedNexTheme.Spacing.sm)
                .opacity(animateCards ? 1 : 0)
                
                // Today's Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                    Button {
                        showTodaysPatients = true
                    } label: {
                        StatCard(title: "Today's Patients", value: "\(todayAppointments.count)", icon: "person.2.fill", tintColor: MedNexTheme.Colors.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        scheduleFilter = "Upcoming"
                        selectedTab = 1
                    } label: {
                        StatCard(title: "Upcoming", value: "\(dataStore.upcomingAppointments.count)", icon: "calendar", tintColor: MedNexTheme.Colors.info)
                    }
                    .buttonStyle(.plain)
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 15)
                
                // Today's Schedule — inset grouped section
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                    SectionHeader(title: "Today's Schedule")
                        .padding(.horizontal, MedNexTheme.Spacing.sm)
                    
                    if todayAppointments.isEmpty {
                        DoctorGroupedSection {
                            DoctorGroupedRow(showDivider: false) {
                                Label("No appointments scheduled for today.", systemImage: "calendar.badge.checkmark")
                                    .font(MedNexTheme.Typography.body)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, MedNexTheme.Spacing.xs)
                            }
                        }
                    } else {
                        DoctorGroupedSection {
                            ForEach(Array(todayAppointments.enumerated()), id: \.element.id) { index, appointment in
                                Button {
                                    selectedAppointment = appointment
                                } label: {
                                    DoctorGroupedRow(showDivider: index < todayAppointments.count - 1) {
                                        appointmentRowContent(appointment)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 20)
                
                // Upcoming Appointments (non-today) — inset grouped section
                let upcomingAppointments = Array(dataStore.normalizedAppointmentsForDisplay.filter { $0.status == .scheduled && !Calendar.current.isDateInToday($0.dateTime) && myDoctorIds.contains($0.doctorId) }.prefix(3))
                
                if !upcomingAppointments.isEmpty {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                        SectionHeader(title: "Upcoming")
                            .padding(.horizontal, MedNexTheme.Spacing.sm)
                        
                        DoctorGroupedSection {
                            ForEach(Array(upcomingAppointments.enumerated()), id: \.element.id) { index, appointment in
                                Button {
                                    selectedAppointment = appointment
                                } label: {
                                    DoctorGroupedRow(showDivider: index < upcomingAppointments.count - 1) {
                                        appointmentRowContent(appointment, showDate: true)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 25)
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .doctorFlowBackground()
        .refreshable {
            if let userId = appState.currentUser?.id {
                await dataStore.refreshAppointments(userId: userId, role: .doctor)
            }
        }
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) {
                animateCards = true
            }
        }
        .sheet(isPresented: $showTodaysPatients) {
            NavigationStack {
                DoctorPatientsView(appState: appState, filterForToday: true)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button { showTodaysPatients = false } label: {
                                Image(systemName: "xmark")
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                        }
                    }
            }
        }
        .navigationDestination(item: $selectedAppointment) { appointment in
            DoctorPatientDetailView(appState: appState, appointment: appointment)
        }
    }
    
    /// Reusable appointment row content for grouped sections
    private func appointmentRowContent(_ appointment: Appointment, showDate: Bool = false) -> some View {
        HStack(spacing: MedNexTheme.Spacing.sm) {
            // Avatar
            AvatarView(
                name: appointment.patientName,
                imageURL: dataStore.patientProfileImages[appointment.patientId],
                size: 36,
                backgroundColor: MedNexTheme.Colors.patientTint
            )
            
            // Details
            VStack(alignment: .leading, spacing: 1) {
                Text(appointment.patientName)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                
                Text(appointment.type.displayName)
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                
                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 9, weight: .semibold))
                        Text(appointment.dateTime.timeOnly)
                            .font(.system(.caption2, weight: .medium))
                    }
                    
                    if showDate || !Calendar.current.isDateInToday(appointment.dateTime) {
                        HStack(spacing: 2) {
                            Image(systemName: "calendar")
                                .font(.system(size: 9, weight: .semibold))
                            Text(appointment.dateTime, format: .dateTime.day().month(.abbreviated))
                                .font(.system(.caption2, weight: .medium))
                        }
                    }
                }
                .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
            
            Spacer()
            
            // Status + Chevron
            HStack(spacing: 8) {
                StatusBadge(text: appointment.status.displayName, color: Color(hex: appointment.status.color))
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
        }
    }
}

// MARK: - Patient Detail View (Instead of Sheet Modal)
struct DoctorPatientDetailView: View {
    let appState: AppState
    let appointment: Appointment
    
    @State private var patientProfile: Patient?
    @State private var isLoading = true
    @State private var loadError: String?
    @Environment(DataStore.self) private var dataStore
    
    /// Returns true if the current date is the same day as the appointment.
    /// Prescription writing is available for the entire appointment day,
    /// so doctors don't lose access if they miss the exact time slot.
    private var isWithinAppointmentWindow: Bool {
        Calendar.current.isDateInToday(appointment.dateTime)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Header Profile Section
                VStack(spacing: MedNexTheme.Spacing.md) {
                    AvatarView(
                        name: appointment.patientName,
                        size: 80,
                        backgroundColor: MedNexTheme.Colors.patientTint
                    )
                        .shadow(color: MedNexTheme.Colors.patientTint.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    VStack(spacing: 4) {
                        Text(displayName)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        
                        Text("\(appointment.dateTime, format: .dateTime.day().month(.wide).year()) at \(appointment.dateTime.timeOnly)")
                            .font(MedNexTheme.Typography.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        
                        StatusBadge(text: appointment.status.displayName, color: Color(hex: appointment.status.color))
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, MedNexTheme.Spacing.lg)
                
                // Patient Details Section
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                    SectionHeader(title: "Patient Details")
                    
                    if isLoading {
                        DoctorCard {
                            HStack {
                                Spacer()
                                ProgressView("Loading patient details…")
                                    .tint(MedNexTheme.Colors.primary)
                                Spacer()
                            }
                            .padding(.vertical, MedNexTheme.Spacing.xl)
                        }
                    } else if let patient = patientProfile {
                        DoctorCard {
                            VStack(spacing: MedNexTheme.Spacing.md) {
                                patientDetailRow(icon: "person.text.rectangle", title: "Age / Sex",
                                    value: "\(patient.personalInfo.age) yrs, \(patient.personalInfo.gender.displayName)")
                                Divider()
                                patientDetailRow(icon: "drop.fill", title: "Blood Group",
                                    value: patient.medicalInfo.bloodType.rawValue, iconColor: .red)
                                Divider()
                                patientDetailRow(icon: "phone.fill", title: "Phone",
                                    value: patient.personalInfo.phone.isEmpty ? "Not provided" : patient.personalInfo.phone)
                                Divider()
                                patientDetailRow(icon: "allergens", title: "Allergies",
                                    value: patient.medicalInfo.allergies.isEmpty ? "None recorded" : patient.medicalInfo.allergies.joined(separator: ", "),
                                    iconColor: .orange)
                                if !patient.medicalInfo.chronicConditions.isEmpty {
                                    Divider()
                                    patientDetailRow(icon: "heart.text.clipboard", title: "Conditions",
                                        value: patient.medicalInfo.chronicConditions.joined(separator: ", "),
                                        iconColor: MedNexTheme.Colors.warning)
                                }
                                if !patient.personalInfo.address.isEmpty || !patient.personalInfo.city.isEmpty {
                                    Divider()
                                    let addressParts = [patient.personalInfo.address, patient.personalInfo.city, patient.personalInfo.state].filter { !$0.isEmpty }
                                    patientDetailRow(icon: "location.fill", title: "Address",
                                        value: addressParts.joined(separator: ", "),
                                        iconColor: MedNexTheme.Colors.info)
                                }
                            }
                        }
                    } else {
                        DoctorCard {
                            VStack(spacing: MedNexTheme.Spacing.sm) {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.largeTitle)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                Text(loadError ?? "Patient details not available")
                                    .font(MedNexTheme.Typography.body)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MedNexTheme.Spacing.lg)
                        }
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                
                // Clinical Action
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                    SectionHeader(title: "Clinical Actions")
                    
                    // Time-gated prescription writing
                    if isWithinAppointmentWindow {
                        NavigationLink {
                            PrescriptionWriterView(appState: appState, initialPatientId: appointment.patientId)
                        } label: {
                            actionButtonContent(
                                icon: "doc.text.fill",
                                title: "Write Prescription",
                                subtitle: "Create new prescription for this visit",
                                color: MedNexTheme.Colors.primary
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        VStack(spacing: MedNexTheme.Spacing.xs) {
                            actionButtonContent(
                                icon: "doc.text.fill",
                                title: "Write Prescription",
                                subtitle: "Available on appointment day: \(appointment.dateTime.shortDate)",
                                color: MedNexTheme.Colors.textTertiary
                            )
                        }
                        .opacity(0.5)
                    }
                    
                    NavigationLink {
                        PatientMedicalHistoryView(appState: appState, patientId: appointment.patientId, patientName: appointment.patientName)
                    } label: {
                        actionButtonContent(
                            icon: "folder.badge.person.crop",
                            title: "Medical History",
                            subtitle: "View history, prescriptions & timeline",
                            color: MedNexTheme.Colors.info
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                
                Spacer().frame(height: MedNexTheme.Spacing.xxl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Patient Profile")
        .doctorFlowBackground()
        .task {
            await fetchPatientProfile()
        }
    }
    
    /// The best display name — prefer the fetched profile, fall back to appointment data.
    private var displayName: String {
        if let patient = patientProfile {
            let fullName = patient.personalInfo.fullName.trimmingCharacters(in: .whitespaces)
            if !fullName.isEmpty { return fullName }
        }
        return appointment.patientName
    }
    
    /// Fetch the patient profile from Supabase using the appointment's patientId.
    private func fetchPatientProfile() async {
        isLoading = true
        
        #if canImport(Supabase)
        let repo = PatientRepository.shared
        
        // Try fetching by user_id first (most common case)
        do {
            let patient = try await repo.fetchPatient(byUserId: appointment.patientId)
            await MainActor.run {
                self.patientProfile = patient
                self.isLoading = false
            }
            return
        } catch {
            // If not found by user_id, try by table row id
            do {
                let patient: Patient = try await SupabaseService.shared.fetchSingle(from: "patients", id: appointment.patientId)
                await MainActor.run {
                    self.patientProfile = patient
                    self.isLoading = false
                }
                return
            } catch {
                await MainActor.run {
                    self.loadError = "Could not load patient details"
                    self.isLoading = false
                }
            }
        }
        #else
        isLoading = false
        loadError = "Backend not available"
        #endif
    }
    
    // MARK: - Medical History Timeline
    private var medicalHistoryTimeline: some View {
        let items = buildTimelineItems()
        
        return VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            SectionHeader(title: "Medical History")
            
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
    
    private func buildTimelineItems() -> [DoctorTimelineItem] {
        var items: [DoctorTimelineItem] = []
        
        // Appointments
        for appt in dataStore.appointments.filter({ $0.patientId == appointment.patientId }) {
            items.append(DoctorTimelineItem(
                date: appt.dateTime, type: .visit,
                title: appt.type.displayName, subtitle: "Dr. \(appt.doctorName)",
                detail: appt.notes.isEmpty ? nil : appt.notes,
                rating: appt.rating, review: appt.review,
                status: appt.status.displayName,
                statusColor: Color(hex: appt.status.color)
            ))
        }
        
        // Prescriptions
        for rx in dataStore.prescriptions.filter({ $0.patientId == appointment.patientId }) {
            let medsText = rx.medicines.map { "\($0.name) \($0.dosage) — \($0.frequency.rawValue)" }.joined(separator: "\n")
            items.append(DoctorTimelineItem(
                date: rx.createdAt, type: .prescription,
                title: rx.diagnosis.isEmpty ? "Prescription" : rx.diagnosis,
                subtitle: "\(rx.medicines.count) medication\(rx.medicines.count == 1 ? "" : "s")",
                detail: medsText, notes: rx.notes
            ))
        }
        
        // Lab tests
        for lab in dataStore.labTests.filter({ $0.patientId == appointment.patientId }) {
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
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(item.type.color)
                    .frame(width: 12, height: 12)
                if !isLast {
                    Rectangle()
                        .fill(MedNexTheme.Colors.textTertiary.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)
            
            // Card
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
                                Text(item.title)
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                Text(item.subtitle)
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                            Spacer()
                            if let status = item.status, let color = item.statusColor {
                                StatusBadge(text: status, color: color)
                            }
                        }
                        
                        if let detail = item.detail, !detail.isEmpty {
                            Divider()
                            Text(detail)
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                .lineLimit(4)
                        }
                        
                        if let notes = item.notes, !notes.isEmpty {
                            Text(notes)
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                .italic()
                                .lineLimit(2)
                        }
                        
                        if let abnormal = item.abnormalCount, abnormal > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 10))
                                Text("\(abnormal) abnormal value\(abnormal == 1 ? "" : "s")")
                                    .font(.system(.caption2, design: .rounded, weight: .medium))
                            }
                            .foregroundStyle(.red)
                        }
                        
                        // Patient review
                        if let rating = item.rating {
                            Divider()
                            HStack(spacing: 2) {
                                Text("Rating:")
                                    .font(.system(.caption2, design: .rounded, weight: .medium))
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 10))
                                        .foregroundStyle(star <= rating ? .orange : MedNexTheme.Colors.textTertiary)
                                }
                            }
                            if let review = item.review, !review.isEmpty {
                                Text("\"\(review)\"")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    .italic()
                            }
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
    
    private func patientDetailRow(icon: String, title: String, value: String, iconColor: Color = MedNexTheme.Colors.textSecondary) -> some View {
        HStack(spacing: MedNexTheme.Spacing.md) {
            Text(title)
                .font(MedNexTheme.Typography.body)
                .foregroundColor(MedNexTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundColor(MedNexTheme.Colors.textPrimary)
        }
    }
    
    private func actionButtonContent(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: MedNexTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                .font(.footnote)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md)
                .fill(MedNexTheme.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Timeline Item Model
struct DoctorTimelineItem: Identifiable {
    let id = UUID()
    let date: Date
    let type: TimelineType
    let title: String
    let subtitle: String
    var detail: String?
    var notes: String?
    var rating: Int?
    var review: String?
    var status: String?
    var statusColor: Color?
    var abnormalCount: Int?
    
    enum TimelineType {
        case visit, prescription, labResult
        
        var icon: String {
            switch self {
            case .visit: return "stethoscope"
            case .prescription: return "pills.fill"
            case .labResult: return "flask.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .visit: return MedNexTheme.Colors.info
            case .prescription: return MedNexTheme.Colors.success
            case .labResult: return MedNexTheme.Colors.warning
            }
        }
    }
}


