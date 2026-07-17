//
//  PatientHomeView.swift
//  MedNex
//

import SwiftUI

struct PatientHomeView: View {
    let appState: AppState
    @Binding var showProfile: Bool
    @Binding var selectedTab: Int
    
    @State private var showBooking = false
    @State private var showRecords = false
    @State private var showLabRequest = false
    @State private var showLabOrders = false
    @State private var showAdmission = false
    @State private var showNotifications = false
    @State private var animateCards = false
    @State private var healthOverviewExpanded = false
    
    @Environment(DataStore.self) private var dataStore
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: MedNexTheme.Spacing.lg) {
                
                welcomeHeader
                
                if profileCompletionPercentage < 100 {
                    profileCompletionCard
                }
                
                if let admission = dataStore.patientAdmission {
                    admissionStatusBanner(admission)
                }
                
                quickActions
                
                upcomingAppointmentCard
                
                activeLabTestsCard
                
                healthSummarySection
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: MedNexTheme.Spacing.md) {
                    Button {
                        HapticManager.selection()
                        showNotifications = true
                    } label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(MedNexTheme.Colors.primary)
                            .overlay(alignment: .topTrailing) {
                                if dataStore.notifications.contains(where: { !$0.isRead }) {
                                    Circle()
                                        .fill(MedNexTheme.Colors.error)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 2, y: -2)
                                }
                            }
                    }
                    
                    AvatarView(
                        name: appState.currentUser?.displayName ?? "P",
                        imageURL: appState.currentUser?.profileImageURL,
                        size: 32,
                        backgroundColor: MedNexTheme.Colors.patientTint
                    )
                    .onTapGesture {
                        HapticManager.selection()
                        showProfile = true
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .scrollContentBackground(.hidden)
        .refreshable { await dataStore.refreshFromBackend() }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateCards = true
            }
        }
        // Sheets and Navigation
        .sheet(isPresented: $showNotifications) { PatientNotificationsSheet(dataStore: dataStore) }
        .sheet(isPresented: $showBooking) { AppointmentBookingView(appState: appState) }
        .sheet(isPresented: $showLabRequest) { NavigationStack { PatientLabRequestView() } }
        .navigationDestination(isPresented: $showRecords) { MedicalRecordsView() }
        .navigationDestination(isPresented: $showLabOrders) { PatientLabOrdersView() }
        .sheet(isPresented: $showAdmission) { PatientAdmissionView() }
    }
    
    // MARK: - Welcome Header
    
    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "☀️" }
        if hour < 17 { return "🌤" }
        return "🌙"
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Good \(greeting) \(greetingEmoji)")
                .font(MedNexTheme.Typography.subheadline)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
            
            Text(appState.currentUser?.displayName ?? "Patient")
                .font(.system(.title2, design: .rounded, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, MedNexTheme.Spacing.xs)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }
    
    // MARK: - Profile Completion
    private var profileCompletionPercentage: Int {
        var filledCount = 0
        let totalFields = 10
        let p = dataStore.patient.personalInfo
        let m = dataStore.patient.medicalInfo
        
        if !p.firstName.isEmpty { filledCount += 1 }
        if !p.lastName.isEmpty { filledCount += 1 }
        if !p.phone.isEmpty { filledCount += 1 }
        if !p.address.isEmpty { filledCount += 1 }
        if !p.city.isEmpty { filledCount += 1 }
        
        if m.bloodType != .unknown { filledCount += 1 }
        if !m.allergies.isEmpty { filledCount += 1 }
        if !m.chronicConditions.isEmpty { filledCount += 1 }
        if m.height != nil { filledCount += 1 }
        if m.weight != nil { filledCount += 1 }
        
        return Int((Double(filledCount) / Double(totalFields)) * 100)
    }
    
    private var profileCompletionCard: some View {
        Button {
            showProfile = true
        } label: {
            GlassCard(padding: MedNexTheme.Spacing.md) {
                HStack(spacing: MedNexTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .stroke(MedNexTheme.Colors.warning.opacity(0.2), lineWidth: 5)
                        Circle()
                            .trim(from: 0, to: CGFloat(profileCompletionPercentage) / 100)
                            .stroke(MedNexTheme.Colors.warning, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring, value: profileCompletionPercentage)
                        
                        Text("\(profileCompletionPercentage)%")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(MedNexTheme.Colors.warning)
                    }
                    .frame(width: 50, height: 50)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Complete Your Profile")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        Text("Add your medical details for better care.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(.footnote, weight: .bold))
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }
    
    // MARK: - Quick Actions
    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
            quickActionTile(icon: "calendar.badge.plus", title: "Book Visit", subtitle: "Schedule now", color: MedNexTheme.Colors.primary) { showBooking = true }
            quickActionTile(icon: "folder.fill", title: "Records", subtitle: "View files", color: MedNexTheme.Colors.info) { showRecords = true }
            quickActionTile(icon: "flask.fill", title: "Lab Test", subtitle: "Request test", color: MedNexTheme.Colors.warning) { showLabRequest = true }
            quickActionTile(icon: "cross.case.fill", title: "Admission", subtitle: "View status", color: MedNexTheme.Colors.success) { showAdmission = true }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }
    
    private func quickActionTile(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15), in: Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MedNexTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(MedNexTheme.Colors.cardBackground)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Admission Status Banner
    private func admissionStatusBanner(_ admission: Admission) -> some View {
        GlassCard {
            HStack(spacing: MedNexTheme.Spacing.md) {
                Image(systemName: "bed.double.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(MedNexTheme.Colors.info.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Currently Admitted")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    
                    Text("Since \(admission.admissionDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    
                    if let diagnosis = admission.diagnosis, !diagnosis.isEmpty {
                        Text(diagnosis)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(MedNexTheme.Colors.info)
                            .lineLimit(1)
                    }
                }
                Spacer()
                StatusBadge(text: "Active", color: MedNexTheme.Colors.info)
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }
    
    // MARK: - Upcoming Appointment
    private var upcomingAppointmentCard: some View {
        Group {
            if let appointment = dataStore.upcomingAppointments.first {
                Button {
                    HapticManager.selection()
                    selectedTab = 1
                } label: {
                    GlassCard {
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                            HStack {
                                SectionHeader(title: "Next Appointment")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.bold())
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                            
                            HStack(spacing: MedNexTheme.Spacing.md) {
                                AvatarView(name: appointment.doctorName, imageURL: dataStore.doctors.first(where: { $0.id == appointment.doctorId })?.profileImageURL, size: 56, backgroundColor: MedNexTheme.Colors.doctorTint)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appointment.doctorName)
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                    
                                    Text(appointment.specialty.rawValue)
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    
                                    HStack(spacing: 6) {
                                        Image(systemName: "calendar.badge.clock")
                                        Text(appointment.dateTime.medicalFormat)
                                    }
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .foregroundStyle(MedNexTheme.Colors.primary)
                                    .padding(.top, 2)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 20)
            }
        }
    }
    
    // MARK: - Active Lab Tests
    private var activeLabTestsCard: some View {
        let activeTests = dataStore.labTests.filter {
            $0.status == .pending || $0.status == .processing || $0.status == .received
        }.sorted { $0.orderedAt > $1.orderedAt }
        
        return Group {
            if !activeTests.isEmpty {
                Button {
                    HapticManager.selection()
                    showLabOrders = true
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Active Lab Tests")
                                .font(.headline)
                                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                            Spacer()
                            Text("\(activeTests.count)")
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                        .padding(MedNexTheme.Spacing.md)
                        
                        Divider()
                        
                        ForEach(Array(activeTests.prefix(2).enumerated()), id: \.element.id) { index, test in
                            HStack(spacing: MedNexTheme.Spacing.md) {
                                Image(systemName: "testtube.2")
                                    .font(.system(size: 20))
                                    .foregroundStyle(MedNexTheme.Colors.warning)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(test.testName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                    Text(test.orderedAt.shortDate)
                                        .font(.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                }
                                Spacer()
                                StatusBadge(text: test.status.displayName, color: labStatusColor(test.status), icon: test.status.icon)
                            }
                            .padding(MedNexTheme.Spacing.md)
                            
                            if index < activeTests.prefix(2).count - 1 || activeTests.count > 2 {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                        
                        if activeTests.count > 2 {
                            HStack {
                                Spacer()
                                Text("View all \(activeTests.count) tests")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(MedNexTheme.Colors.primary)
                                Spacer()
                            }
                            .padding(MedNexTheme.Spacing.md)
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg, style: .continuous))
                }
                .buttonStyle(.plain)
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 20)
            }
        }
    }
    
    // MARK: - Health Summary
    @ViewBuilder
    private var healthSummarySection: some View {
        if let latestVitals = dataStore.vitalRecords.first {
            GlassCard {
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            healthOverviewExpanded.toggle()
                        }
                        HapticManager.selection()
                    } label: {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .font(.title2)
                                .foregroundStyle(MedNexTheme.Colors.error)
                            Text("Health Overview")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(.subheadline, weight: .bold))
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                .rotationEffect(.degrees(healthOverviewExpanded ? 90 : 0))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    if healthOverviewExpanded {
                        Divider().padding(.vertical, 8)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.md) {
                            if let hr = latestVitals.heartRate {
                                StatCard(title: "Heart Rate", value: "\(Int(hr)) bpm", icon: "heart.fill", trend: .stable, tintColor: MedNexTheme.Colors.error)
                            }
                            if let bp = latestVitals.bloodPressureFormatted {
                                StatCard(title: "Blood Pressure", value: bp, icon: "waveform.path.ecg", tintColor: MedNexTheme.Colors.info)
                            }
                            if let spo2 = latestVitals.oxygenSaturation {
                                StatCard(title: "SpO₂", value: "\(Int(spo2))%", icon: "lungs.fill", trend: .stable, tintColor: MedNexTheme.Colors.primary)
                            }
                            if let temp = latestVitals.temperature {
                                StatCard(title: "Temperature", value: String(format: "%.1f°C", temp), icon: "thermometer", tintColor: MedNexTheme.Colors.warning)
                            }
                        }
                        .monospacedDigit()
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity).animation(.spring),
                            removal: .scale(scale: 0.95).combined(with: .opacity).animation(.easeOut(duration: 0.2))
                        ))
                    }
                }
            }
            .opacity(animateCards ? 1 : 0)
            .offset(y: animateCards ? 0 : 20)
        }
    }
    
    // MARK: - Helpers
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        default: return "Evening"
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

struct PatientNotificationsSheet: View {
    let dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if dataStore.notifications.isEmpty {
                    ContentUnavailableView(
                        "No Notifications",
                        systemImage: "bell.slash",
                        description: Text("You're all caught up!")
                    )
                } else {
                    ForEach(dataStore.notifications) { notification in
                        HStack(spacing: MedNexTheme.Spacing.md) {
                            Image(systemName: notification.type.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(notification.isRead ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    (notification.isRead ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.primary).opacity(0.15),
                                    in: Circle()
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notification.title)
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(notification.isRead ? MedNexTheme.Colors.textSecondary : MedNexTheme.Colors.textPrimary)
                                
                                Text(notification.body)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text(notification.createdAt.relative)
                                    .font(.system(.caption2, design: .rounded, weight: .medium))
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                Spacer()
                                if !notification.isRead {
                                    Circle()
                                        .fill(MedNexTheme.Colors.primary)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color(.secondarySystemGroupedBackground))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Read All") {
                        HapticManager.selection()
                        // Action to mark all as read would typically go here
                    }
                    .font(.subheadline.weight(.medium))
                    .disabled(dataStore.notifications.filter { !$0.isRead }.isEmpty)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}
