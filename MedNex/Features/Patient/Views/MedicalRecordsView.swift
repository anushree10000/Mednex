//
//  MedicalRecordsView.swift
//  MedNex
//

import SwiftUI

struct MedicalRecordsView: View {
    @Environment(DataStore.self) private var dataStore
    
    private var completedAppointments: [Appointment] {
        dataStore.appointments.filter { $0.status == .completed }
    }
    
    var body: some View {
        ScrollView {
            if completedAppointments.isEmpty {
                EmptyStateView(icon: "doc.text.fill", title: "No Records", message: "Your medical records will appear here after your visits.")
            } else {
                LazyVStack(spacing: MedNexTheme.Spacing.md) {
                    ForEach(completedAppointments) { appointment in
                        GlassCard {
                            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                                HStack {
                                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                                        Text(appointment.dateTime.shortDate)
                                            .font(MedNexTheme.Typography.headline)
                                        Text(appointment.doctorName)
                                            .font(MedNexTheme.Typography.subheadline)
                                            .foregroundStyle(MedNexTheme.Colors.primary)
                                        Text(appointment.specialty.rawValue)
                                            .font(MedNexTheme.Typography.caption)
                                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    }
                                    Spacer()
                                    StatusBadge(text: "Completed", color: MedNexTheme.Colors.success, icon: "checkmark.circle.fill")
                                }
                                
                                if !appointment.notes.isEmpty {
                                    Divider()
                                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                                        Text("Diagnosis / Notes")
                                            .font(MedNexTheme.Typography.caption.weight(.semibold))
                                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                        Text(appointment.notes)
                                            .font(MedNexTheme.Typography.body)
                                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    }
                                }
                                
                                // Prescription link
                                if let rx = dataStore.prescriptions.first(where: { $0.appointmentId == appointment.id }) {
                                    Divider()
                                    HStack {
                                        Image(systemName: "pills.fill")
                                            .foregroundStyle(MedNexTheme.Colors.success)
                                        Text("\(rx.medicines.count) medications prescribed")
                                            .font(MedNexTheme.Typography.subheadline)
                                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    }
                                }
                                
                                // Actions
                                HStack(spacing: MedNexTheme.Spacing.sm) {
                                    ShareLink(item: "Medical Record\nDoctor: \(appointment.doctorName)\nDate: \(appointment.dateTime.shortDate)\nSpecialty: \(appointment.specialty.rawValue)\nNotes: \(appointment.notes.isEmpty ? "N/A" : appointment.notes)") {
                                        Label("Download PDF", systemImage: "arrow.down.doc.fill")
                                            .font(MedNexTheme.Typography.caption)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(MedNexTheme.Colors.primary)
                                    
                                    ShareLink(item: "\(appointment.specialty.rawValue) visit — Dr. \(appointment.doctorName) (\(appointment.dateTime.shortDate))") {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                            .font(MedNexTheme.Typography.caption)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
        }
        .navigationTitle("Medical Records")
    }
}
