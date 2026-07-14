//
//  DoctorScheduleView.swift
//  MedNex
//

import SwiftUI

struct DoctorScheduleView: View {
    let appState: AppState
    @State private var selectedDate = Date()
    @Binding var appointmentFilter: String
    @State private var selectedAppointment: Appointment?
    @State private var showManageAvailability = false
    @State private var blockedSlots: Set<String> = []
    @State private var isLoadingBlocks = false
    @State private var isSavingBlock = false
    
    private let timeSlots = ["9:00 AM", "9:30 AM", "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM", "2:00 PM", "2:30 PM", "3:00 PM", "3:30 PM", "4:00 PM", "4:30 PM"]
    
    init(appState: AppState, appointmentFilter: Binding<String>) {
        self.appState = appState
        self._appointmentFilter = appointmentFilter
    }
    
    @Environment(DataStore.self) private var dataStore
    
    private var doctorId: String {
        appState.currentUser?.id ?? ""
    }
    
    /// All possible IDs this doctor could be referenced by in appointments
    private var myDoctorIds: Set<String> {
        var ids: Set<String> = [doctorId]
        if let doc = dataStore.doctors.first(where: { $0.userId == doctorId }) {
            ids.insert(doc.id)
        }
        return ids
    }
    
    private var filteredAppointments: [Appointment] {
        let allAppointments = dataStore.normalizedAppointmentsForDisplay.filter { myDoctorIds.contains($0.doctorId) }
        
        if appointmentFilter == "Today" {
            return allAppointments
                .filter { Calendar.current.isDate($0.dateTime, inSameDayAs: selectedDate) && $0.status != .cancelled }
                .sorted { $0.dateTime < $1.dateTime }
        } else {
            return allAppointments
                .filter { $0.dateTime > Date() && $0.status != .cancelled }
                .sorted { $0.dateTime < $1.dateTime }
        }
    }
    
    private var datesWithAppointments: Set<DateComponents> {
        let allAppointments = dataStore.normalizedAppointmentsForDisplay.filter { myDoctorIds.contains($0.doctorId) }
        let calendar = Calendar.current
        return Set(allAppointments.map { calendar.dateComponents([.year, .month, .day], from: $0.dateTime) })
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                // Segmented Control
                Picker("Appointments", selection: $appointmentFilter) {
                    Text("Today").tag("Today")
                    Text("Upcoming").tag("Upcoming")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.top, MedNexTheme.Spacing.sm)
                .padding(.bottom, MedNexTheme.Spacing.sm)
                
                // Date Picker only for Today
                if appointmentFilter == "Today" {
                    datePickerWithIndicators
                        .padding(.horizontal, MedNexTheme.Spacing.md)
                        .glassCard()
                        .padding(.horizontal, MedNexTheme.Spacing.md)
                        .onChange(of: selectedDate) { _, _ in
                            if showManageAvailability {
                                loadBlockedSlots()
                            }
                        }
                    
                    // Appointment Indicator
                    HStack(spacing: MedNexTheme.Spacing.xs) {
                        Text("Dates with appointments:")
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        
                        Circle()
                            .fill(MedNexTheme.Colors.primary)
                            .frame(width: 6, height: 6)
                        
                        Spacer()
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                    .padding(.top, MedNexTheme.Spacing.sm)
                    
                    // Manage Availability Button
                    Button {
                        withAnimation(MedNexTheme.Animation.smooth) {
                            showManageAvailability.toggle()
                            if showManageAvailability {
                                loadBlockedSlots()
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: showManageAvailability ? "clock.badge.checkmark" : "clock.badge.xmark")
                            Text(showManageAvailability ? "Hide Availability Manager" : "Manage Availability")
                        }
                        .font(MedNexTheme.Typography.subheadline.weight(.semibold))
                        .foregroundStyle(MedNexTheme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MedNexTheme.Spacing.sm)
                        .background(MedNexTheme.Colors.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md))
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                    .padding(.top, MedNexTheme.Spacing.xs)
                    
                    // Slot Blocking Grid
                    if showManageAvailability {
                        slotBlockingGrid
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                
                // Appointments List
                if filteredAppointments.isEmpty {
                    EmptyStateView(
                        icon: "calendar",
                        title: "No Appointments",
                        message: "No appointments available."
                    )
                    .padding(.top, MedNexTheme.Spacing.xxl)
                } else {
                    DoctorGroupedSection {
                        ForEach(Array(filteredAppointments.enumerated()), id: \.element.id) { index, appointment in
                            Button {
                                selectedAppointment = appointment
                            } label: {
                                DoctorGroupedRow(showDivider: index < filteredAppointments.count - 1) {
                                    HStack(spacing: MedNexTheme.Spacing.sm) {
                                        // Time column
                                        VStack(alignment: .center, spacing: 2) {
                                            if appointmentFilter == "Upcoming" {
                                                Text(appointment.dateTime, format: .dateTime.day().month(.abbreviated))
                                                    .font(.system(.caption2, weight: .medium))
                                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                            }
                                            Text(appointment.dateTime, format: .dateTime.hour().minute())
                                                .font(.system(.body, weight: .semibold))
                                                .foregroundStyle(MedNexTheme.Colors.primary)
                                        }
                                        .frame(width: 56)
                                        
                                        // Color indicator
                                        Rectangle()
                                            .fill(Color(hex: appointment.status.color))
                                            .frame(width: 2.5)
                                            .frame(maxHeight: .infinity)
                                            .clipShape(Capsule())
                                        
                                        // Patient info
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(appointment.patientName)
                                                .font(.system(.body, weight: .semibold))
                                                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                            
                                            Text(appointment.type.displayName)
                                                .font(.system(.caption, weight: .medium))
                                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // Status + chevron
                                        HStack(spacing: 8) {
                                            StatusBadge(
                                                text: appointment.status.displayName,
                                                color: Color(hex: appointment.status.color)
                                            )
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if appointment.status == .scheduled {
                                    Button {
                                        HapticManager.light()
                                        dataStore.startAppointment(appointment.id)
                                    } label: {
                                        Label("Start Consultation", systemImage: "play.fill")
                                    }
                                }
                                if appointment.status == .scheduled || appointment.status == .inProgress {
                                    Button {
                                        HapticManager.success()
                                        dataStore.completeAppointment(appointment.id)
                                    } label: {
                                        Label("Mark as Completed", systemImage: "checkmark.circle.fill")
                                    }
                                }
                                if appointment.status != .cancelled {
                                    Button(role: .destructive) {
                                        dataStore.cancelAppointment(appointment.id)
                                    } label: {
                                        Label("Cancel Appointment", systemImage: "xmark.circle.fill")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                    .padding(.top, MedNexTheme.Spacing.xs)
                }
                
                Spacer(minLength: MedNexTheme.Spacing.xxl)
            }
        }
        .doctorFlowBackground()
        .refreshable {
            if let userId = appState.currentUser?.id {
                await dataStore.refreshAppointments(userId: userId, role: .doctor)
            }
        }
        .navigationDestination(item: $selectedAppointment) { appointment in
            DoctorPatientDetailView(appState: appState, appointment: appointment)
        }
    }
    
    // MARK: - Slot Blocking Grid
    
    private var slotBlockingGrid: some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            HStack {
                Text("Block Slots for \(selectedDate.shortDate)")
                    .font(MedNexTheme.Typography.headline)
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                
                Spacer()
                
                if isLoadingBlocks || isSavingBlock {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            
            Text("Tap a slot to block or unblock it. Blocked slots won't be available for patients.")
                .font(MedNexTheme.Typography.caption)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
            
            // Prevent blocking slots on past dates
            if Calendar.current.startOfDay(for: selectedDate) < Calendar.current.startOfDay(for: Date()) {
                HStack(spacing: MedNexTheme.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Cannot manage slots for past dates. Please select today or a future date.")
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
                .padding(MedNexTheme.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
            } else if isLoadingBlocks {
                HStack(spacing: MedNexTheme.Spacing.sm) {
                    ProgressView()
                    Text("Loading...")
                        .font(MedNexTheme.Typography.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MedNexTheme.Spacing.md)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                    ForEach(timeSlots, id: \.self) { slot in
                        let isBlocked = blockedSlots.contains(slot)
                        let isToday = Calendar.current.isDateInToday(selectedDate)
                        let isPast = isToday && slot.isPastTimeToday
                        
                        Button {
                            toggleBlock(slot: slot)
                        } label: {
                            VStack(spacing: 2) {
                                Text(slot)
                                    .font(MedNexTheme.Typography.subheadline)
                                Text(isPast ? "Passed" : (isBlocked ? "Blocked" : "Available"))
                                    .font(MedNexTheme.Typography.caption2)
                            }
                            .foregroundStyle(isPast || isBlocked ? .white : MedNexTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MedNexTheme.Spacing.sm)
                            .background(
                                isPast ? AnyShapeStyle(Color.gray.opacity(0.85)) :
                                isBlocked ? AnyShapeStyle(Color.red.opacity(0.85)) : AnyShapeStyle(MedNexTheme.Colors.elevatedBackground),
                                in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm)
                                    .strokeBorder(isPast ? Color.clear : isBlocked ? Color.red : MedNexTheme.Colors.textTertiary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .disabled(isSavingBlock || isPast)
                    }
                }
            }
            
            // Legend
            HStack(spacing: MedNexTheme.Spacing.md) {
                HStack(spacing: 4) {
                    Circle().fill(Color.red.opacity(0.85)).frame(width: 8, height: 8)
                    Text("Blocked").font(MedNexTheme.Typography.caption2).foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
                HStack(spacing: 4) {
                    Circle().fill(MedNexTheme.Colors.elevatedBackground).frame(width: 8, height: 8)
                        .overlay(Circle().strokeBorder(MedNexTheme.Colors.textTertiary.opacity(0.3), lineWidth: 1))
                    Text("Available").font(MedNexTheme.Typography.caption2).foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
            }
        }
        .padding(MedNexTheme.Spacing.md)
        .glassCard()
        .padding(.horizontal, MedNexTheme.Spacing.md)
        .padding(.top, MedNexTheme.Spacing.xs)
    }
    
    // MARK: - Helpers
    
    private func loadBlockedSlots() {
        isLoadingBlocks = true
        Task {
            let slots = await dataStore.fetchBlockedSlots(doctorId: doctorId, date: selectedDate)
            await MainActor.run {
                blockedSlots = slots
                isLoadingBlocks = false
            }
        }
    }
    
    private func toggleBlock(slot: String) {
        let isBlocked = blockedSlots.contains(slot)
        isSavingBlock = true
        
        // Optimistic update
        if isBlocked {
            blockedSlots.remove(slot)
        } else {
            blockedSlots.insert(slot)
        }
        
        Task {
            do {
                if isBlocked {
                    try await dataStore.unblockSlot(doctorId: doctorId, date: selectedDate, slot: slot)
                } else {
                    try await dataStore.blockSlot(doctorId: doctorId, date: selectedDate, slot: slot)
                }
            } catch {
                // Revert on failure
                await MainActor.run {
                    if isBlocked {
                        blockedSlots.insert(slot)
                    } else {
                        blockedSlots.remove(slot)
                    }
                }
                print("🔴 Failed to toggle block: \(error)")
            }
            await MainActor.run { isSavingBlock = false }
        }
    }
    
    private var datePickerWithIndicators: some View {
        VStack(spacing: MedNexTheme.Spacing.md) {
            // Native Apple DatePicker
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(MedNexTheme.Colors.primary)
            
            // Clean, minimal legend
            HStack(spacing: MedNexTheme.Spacing.md) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(MedNexTheme.Colors.primary)
                        .frame(width: 4, height: 4)
                    Text("Has appointments")
                        .font(.system(.caption, weight: .regular))
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.top, MedNexTheme.Spacing.xs)
        }
    }
}
