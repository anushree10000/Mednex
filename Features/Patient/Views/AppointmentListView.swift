//
//  AppointmentListView.swift
//  MedNex
//

import SwiftUI

struct AppointmentListView: View {
    let appState: AppState
    @State private var selectedFilter: AppointmentFilter = .upcoming
    @State private var showBooking = false
    @Environment(DataStore.self) private var dataStore
    
    private var filteredAppointments: [Appointment] {
        let now = Date()
        switch selectedFilter {
        case .upcoming:
            return dataStore.appointments.filter {
                ($0.status == .scheduled || $0.status == .inProgress) && $0.dateTime > now
            }.sorted { $0.dateTime < $1.dateTime }
        case .past:
            return dataStore.appointments.filter {
                $0.status == .completed || $0.status == .cancelled ||
                ($0.status == .scheduled && $0.dateTime <= now)
            }.sorted { $0.dateTime > $1.dateTime }
        case .all:
            return dataStore.appointments.sorted { $0.dateTime > $1.dateTime }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter
            Picker("Filter", selection: $selectedFilter) {
                ForEach(AppointmentFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue.capitalized).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.vertical, MedNexTheme.Spacing.sm)
            
            if filteredAppointments.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "No Appointments",
                    message: "You don't have any \(selectedFilter.rawValue) appointments.",
                    actionTitle: "Book Now"
                ) { showBooking = true }
            } else {
                ScrollView {
                    LazyVStack(spacing: MedNexTheme.Spacing.sm) {
                        ForEach(filteredAppointments) { appointment in
                            NavigationLink {
                                AppointmentDetailView(appointment: appointment)
                            } label: {
                                appointmentRow(appointment)
                            }
                        }
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                    .padding(.bottom, MedNexTheme.Spacing.xxl)
                }
            }
        }
        .navigationTitle("Appointments")
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showBooking = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showBooking) {
            AppointmentBookingView(appState: appState)
        }
    }
    
    private func appointmentRow(_ appointment: Appointment) -> some View {
        let doctor = dataStore.doctors.first(where: { $0.id == appointment.doctorId })
        
        return GlassCard {
            VStack(spacing: MedNexTheme.Spacing.sm) {
                HStack(spacing: MedNexTheme.Spacing.md) {
                    // Doctor Avatar
                    AvatarView(
                        name: appointment.doctorName,
                        imageURL: doctor?.profileImageURL,
                        size: 48,
                        backgroundColor: MedNexTheme.Colors.doctorTint
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appointment.doctorName)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        
                        HStack(spacing: 6) {
                            Image(systemName: appointment.specialty.icon)
                                .font(.caption2)
                            Text(appointment.specialty.rawValue)
                                .font(MedNexTheme.Typography.caption)
                        }
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    StatusBadge(
                        text: appointment.status.displayName,
                        color: Color(hex: appointment.status.color)
                    )
                }
                
                Divider()
                
                HStack {
                    // Date
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                        
                            .font(.caption)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        Text(appointment.dateTime.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(.caption, design: .rounded, weight: .medium))
                    }
                    
                    Spacer()
                    
                    // Time
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        Text(appointment.dateTime.timeOnly)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
            }
        }
    }
}

enum AppointmentFilter: String, CaseIterable {
    case upcoming, past, all
}
