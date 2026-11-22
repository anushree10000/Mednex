//
//  AppointmentListView.swift
//  MedNex
//

import SwiftUI

struct AppointmentListView: View {
    @State private var selectedFilter: AppointmentFilter = .upcoming
    @State private var showBooking = false
    @Environment(DataStore.self) private var dataStore
    
    private var filteredAppointments: [Appointment] {
        switch selectedFilter {
        case .upcoming:
            return dataStore.appointments.filter { $0.status == .scheduled || $0.status == .inProgress }.sorted { $0.dateTime < $1.dateTime }
        case .past:
            return dataStore.appointments.filter { $0.status == .completed || $0.status == .cancelled }.sorted { $0.dateTime > $1.dateTime }
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
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
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
            AppointmentBookingView()
        }
    }
    
    private func appointmentRow(_ appointment: Appointment) -> some View {
        GlassCard {
            HStack(spacing: MedNexTheme.Spacing.md) {
                // Date badge
                VStack(spacing: 2) {
                    Text(appointment.dateTime, format: .dateTime.day())
                        .font(MedNexTheme.Typography.title2)
                        .foregroundStyle(MedNexTheme.Colors.primary)
                    Text(appointment.dateTime, format: .dateTime.month(.abbreviated))
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
                .frame(width: 50)
                
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                    Text(appointment.doctorName)
                        .font(MedNexTheme.Typography.headline)
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    
                    Text(appointment.specialty.rawValue)
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    
                    HStack {
                        Image(systemName: "clock")
                        Text(appointment.dateTime.timeOnly)
                    }
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: MedNexTheme.Spacing.xs) {
                    StatusBadge(
                        text: appointment.status.displayName,
                        color: Color(hex: appointment.status.color)
                    )
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
            }
        }
    }
}

enum AppointmentFilter: String, CaseIterable {
    case upcoming, past, all
}
