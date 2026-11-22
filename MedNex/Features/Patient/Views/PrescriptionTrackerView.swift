//
//  PrescriptionTrackerView.swift
//  MedNex
//

import SwiftUI

struct PrescriptionTrackerView: View {
    @Environment(DataStore.self) private var dataStore
    
    var body: some View {
        ScrollView {
            if dataStore.prescriptions.isEmpty {
                EmptyStateView(icon: "pills.fill", title: "No Prescriptions", message: "Your prescriptions will appear here after doctor visits.")
            } else {
                LazyVStack(spacing: MedNexTheme.Spacing.md) {
                    ForEach(dataStore.prescriptions) { rx in
                        GlassCard {
                            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                                HStack {
                                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                                        Text(rx.diagnosis)
                                            .font(MedNexTheme.Typography.headline)
                                        Text("Dr. \(rx.doctorName.replacingOccurrences(of: "Dr. ", with: ""))")
                                            .font(MedNexTheme.Typography.subheadline)
                                            .foregroundStyle(MedNexTheme.Colors.primary)
                                        Text(rx.createdAt.shortDate)
                                            .font(MedNexTheme.Typography.caption)
                                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    }
                                    Spacer()
                                    StatusBadge(text: rx.status.displayName, color: rx.status == .active ? MedNexTheme.Colors.success : MedNexTheme.Colors.textSecondary)
                                }
                                
                                Divider()
                                
                                ForEach(rx.medicines) { med in
                                    HStack(spacing: MedNexTheme.Spacing.sm) {
                                        Image(systemName: med.isTaken ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(med.isTaken ? MedNexTheme.Colors.success : MedNexTheme.Colors.textTertiary)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(med.name)
                                                .font(MedNexTheme.Typography.subheadline.weight(.medium))
                                            HStack(spacing: MedNexTheme.Spacing.xs) {
                                                Text(med.dosage)
                                                Text("•")
                                                Text(med.frequency.rawValue)
                                                Text("•")
                                                Text(med.duration)
                                            }
                                            .font(MedNexTheme.Typography.caption)
                                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                            
                                            if !med.instructions.isEmpty {
                                                Text(med.instructions)
                                                    .font(MedNexTheme.Typography.caption)
                                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                                    .italic()
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                
                                // Refill Request
                                if rx.status == .active {
                                    Button {
                                        HapticManager.medium()
                                        dataStore.addNotification(
                                            title: "Refill Requested",
                                            message: "Your refill request for \(rx.diagnosis) prescription has been sent to Dr. \(rx.doctorName).",
                                            type: .prescriptionReady
                                        )
                                    } label: {
                                        Label("Request Refill", systemImage: "arrow.clockwise")
                                            .font(MedNexTheme.Typography.subheadline.weight(.medium))
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(MedNexTheme.Colors.primary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
        }
        .navigationTitle("Prescriptions")
    }
}
