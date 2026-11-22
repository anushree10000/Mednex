//
//  DoctorDashboardView.swift
//  MedNex
//

import SwiftUI

struct DoctorDashboardView: View {
    let appState: AppState
    @Binding var showProfile: Bool
    @State private var animateCards = false
    @Environment(DataStore.self) private var dataStore
    
    private var todayAppointments: [Appointment] {
        dataStore.appointments.filter { Calendar.current.isDateInToday($0.dateTime) }
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
                    Button { showProfile = true } label: {
                        AvatarView(name: appState.currentUser?.displayName ?? "D", size: 52, backgroundColor: MedNexTheme.Colors.doctorTint)
                    }
                }
                .padding(.top, MedNexTheme.Spacing.sm)
                .opacity(animateCards ? 1 : 0)
                
                // Today's Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                    StatCard(title: "Today's Patients", value: "\(todayAppointments.count)", icon: "person.2.fill", tintColor: MedNexTheme.Colors.primary)
                    StatCard(title: "Upcoming", value: "\(dataStore.upcomingAppointments.count)", icon: "calendar", tintColor: MedNexTheme.Colors.info)
                    StatCard(title: "Completed", value: "\(dataStore.appointments.filter { $0.status == .completed }.count)", icon: "checkmark.circle.fill", tintColor: MedNexTheme.Colors.success)
                    StatCard(title: "Pending Labs", value: "\(dataStore.pendingLabTests.count)", icon: "flask.fill", tintColor: MedNexTheme.Colors.warning)
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 15)
                
                // Today's Schedule
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                    SectionHeader(title: "Today's Schedule")
                    
                    if todayAppointments.isEmpty {
                        GlassCard {
                            Label("No appointments scheduled for today.", systemImage: "calendar.badge.checkmark")
                                .font(MedNexTheme.Typography.body)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, MedNexTheme.Spacing.md)
                        }
                    } else {
                        ForEach(todayAppointments) { appointment in
                            appointmentRow(appointment)
                        }
                    }
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 20)
                
                // Upcoming Appointments (non-today)
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                    SectionHeader(title: "Upcoming")
                    
                    ForEach(dataStore.appointments.filter { $0.status == .scheduled && !Calendar.current.isDateInToday($0.dateTime) }.prefix(3)) { appointment in
                        appointmentRow(appointment)
                    }
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 25)
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Dashboard")
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) {
                animateCards = true
            }
        }
    }
    
    private func appointmentRow(_ appointment: Appointment) -> some View {
        GlassCard {
            HStack(spacing: MedNexTheme.Spacing.md) {
                AvatarView(name: appointment.patientName, size: 44, backgroundColor: MedNexTheme.Colors.patientTint)
                
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                    Text(appointment.patientName)
                        .font(MedNexTheme.Typography.headline)
                    
                    HStack(spacing: MedNexTheme.Spacing.sm) {
                        Label(appointment.dateTime.timeOnly, systemImage: "clock")
                        Label(appointment.type.displayName, systemImage: "tag")
                    }
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                StatusBadge(text: appointment.status.displayName, color: Color(hex: appointment.status.color))
            }
        }
    }
}
