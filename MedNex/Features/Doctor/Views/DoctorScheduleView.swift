//
//  DoctorScheduleView.swift
//  MedNex
//

import SwiftUI

struct DoctorScheduleView: View {
    @State private var selectedDate = Date()
    @Environment(DataStore.self) private var dataStore
    
    private var appointmentsForDate: [Appointment] {
        dataStore.appointments.filter { Calendar.current.isDate($0.dateTime, inSameDayAs: selectedDate) }
            .sorted { $0.dateTime < $1.dateTime }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(MedNexTheme.Colors.primary)
                .environment(\.colorScheme, .dark)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .glassCard()
                .padding(.horizontal, MedNexTheme.Spacing.md)
            
            ScrollView {
                if appointmentsForDate.isEmpty {
                    EmptyStateView(icon: "calendar", title: "No Appointments", message: "No appointments scheduled for this date.")
                        .padding(.top, MedNexTheme.Spacing.xxl)
                } else {
                    LazyVStack(spacing: MedNexTheme.Spacing.sm) {
                        ForEach(appointmentsForDate) { appointment in
                            GlassCard {
                                HStack(spacing: MedNexTheme.Spacing.md) {
                                    // Time
                                    VStack(spacing: 2) {
                                        Text(appointment.dateTime.timeOnly)
                                            .font(MedNexTheme.Typography.headline)
                                            .foregroundStyle(MedNexTheme.Colors.primary)
                                    }
                                    .frame(width: 65)
                                    
                                    Rectangle()
                                        .fill(Color(hex: appointment.status.color))
                                        .frame(width: 3)
                                        .frame(maxHeight: .infinity)
                                        .clipShape(Capsule())
                                    
                                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                                        Text(appointment.patientName)
                                            .font(MedNexTheme.Typography.headline)
                                        Text(appointment.type.displayName)
                                            .font(MedNexTheme.Typography.caption)
                                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    StatusBadge(text: appointment.status.displayName, color: Color(hex: appointment.status.color))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                    .padding(.top, MedNexTheme.Spacing.sm)
                    .padding(.bottom, MedNexTheme.Spacing.xxl)
                }
            }
        }
        .navigationTitle("Schedule")
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
    }
}
