//
//  AppointmentDetailView.swift
//  MedNex
//

import SwiftUI

struct AppointmentDetailView: View {
    let appointment: Appointment
    @State private var showCancelAlert = false
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Status Banner
                statusBanner
                
                // Doctor Info
                doctorInfo
                
                // Appointment Details
                detailsSection
                
                // Notes
                if !appointment.notes.isEmpty {
                    notesSection
                }
                
                // Actions
                actionsSection
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Appointment Details")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .alert("Cancel Appointment?", isPresented: $showCancelAlert) {
            Button("Keep") {}
            Button("Cancel Appointment", role: .destructive) {
                HapticManager.warning()
                dataStore.cancelAppointment(appointment.id)
                dataStore.addNotification(
                    title: "Appointment Cancelled",
                    message: "Your appointment with Dr. \(appointment.doctorName) on \(appointment.dateTime.shortDate) has been cancelled.",
                    type: .appointmentCancelled
                )
                dismiss()
            }
        } message: {
            Text("Are you sure you want to cancel this appointment? This action cannot be undone.")
        }
    }
    
    private var statusBanner: some View {
        HStack {
            Image(systemName: appointment.status == .completed ? "checkmark.circle.fill" : "clock.fill")
            Text(appointment.status.displayName)
                .font(MedNexTheme.Typography.headline)
            Spacer()
            StatusBadge(text: appointment.type.displayName, color: MedNexTheme.Colors.info)
        }
        .foregroundStyle(Color(hex: appointment.status.color))
        .padding(MedNexTheme.Spacing.md)
        .background(Color(hex: appointment.status.color).opacity(0.1), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md))
    }
    
    private var doctorInfo: some View {
        GlassCard {
            HStack(spacing: MedNexTheme.Spacing.md) {
                AvatarView(name: appointment.doctorName, size: 60, backgroundColor: MedNexTheme.Colors.doctorTint)
                
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                    Text(appointment.doctorName)
                        .font(MedNexTheme.Typography.title3)
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    Text(appointment.specialty.rawValue)
                        .font(MedNexTheme.Typography.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
                
                Spacer()
            }
        }
    }
    
    private var detailsSection: some View {
        GlassCard {
            VStack(spacing: MedNexTheme.Spacing.md) {
                detailRow(icon: "calendar", title: "Date", value: appointment.dateTime.shortDate)
                Divider()
                detailRow(icon: "clock", title: "Time", value: appointment.dateTime.timeOnly)
                Divider()
                detailRow(icon: "tag", title: "Type", value: appointment.type.displayName)
                Divider()
                detailRow(icon: "creditcard", title: "Billing", value: appointment.billingStatus.displayName)
            }
        }
    }
    
    private var notesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                Label("Doctor's Notes", systemImage: "note.text")
                    .font(MedNexTheme.Typography.headline)
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                Text(appointment.notes)
                    .font(MedNexTheme.Typography.body)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
            }
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: MedNexTheme.Spacing.sm) {
            if appointment.canCancel {
                Button {
                    HapticManager.warning()
                    showCancelAlert = true
                } label: {
                    Text("Cancel Appointment")
                }
                .buttonStyle(.medNexSecondary)
            }
        }
    }
    
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(MedNexTheme.Typography.subheadline)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(MedNexTheme.Typography.subheadline.weight(.medium))
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
        }
    }
}
