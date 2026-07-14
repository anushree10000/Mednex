import SwiftUI

struct DoctorPrescriptionDetailView: View {
    let prescription: Prescription
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Header
                DoctorCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        HStack {
                            Text("Diagnosis")
                                .font(MedNexTheme.Typography.subheadline)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            Spacer()
                            StatusBadge(text: prescription.status.displayName, color: Color(hex: prescription.status.color))
                        }
                        
                        Text(prescription.diagnosis.isEmpty ? "No Diagnosis Provided" : prescription.diagnosis)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        HStack {
                            Text(prescription.createdAt.formatted(date: .long, time: .shortened))
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.top, MedNexTheme.Spacing.md)
                
                // Medicines
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                    SectionHeader(title: "Medicines (\(prescription.medicines.count))")
                        .padding(.horizontal, MedNexTheme.Spacing.md)
                    
                    if prescription.medicines.isEmpty {
                        DoctorCard {
                            Label("No medicines added.", systemImage: "pills.fill")
                                .font(MedNexTheme.Typography.body)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, MedNexTheme.Spacing.md)
                    } else {
                        ForEach(prescription.medicines) { med in
                            DoctorCard(padding: MedNexTheme.Spacing.md) {
                                HStack(spacing: MedNexTheme.Spacing.md) {
                                    Image(systemName: "pill.fill")
                                        .font(.title2)
                                        .foregroundStyle(MedNexTheme.Colors.primary)
                                        .frame(width: 44, height: 44)
                                        .background(MedNexTheme.Colors.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(med.name)
                                            .font(MedNexTheme.Typography.headline)
                                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                        
                                        HStack(spacing: MedNexTheme.Spacing.sm) {
                                            Text(med.dosage)
                                            Text(med.frequency.rawValue)
                                            Text(med.duration)
                                        }
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                        
                                        if !med.instructions.isEmpty {
                                            Text(med.instructions)
                                                .font(MedNexTheme.Typography.caption2)
                                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                                .padding(.top, 2)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, MedNexTheme.Spacing.md)
                        }
                    }
                }
                
                // Notes
                if !prescription.notes.isEmpty {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        SectionHeader(title: "Additional Notes")
                            .padding(.horizontal, MedNexTheme.Spacing.md)
                        
                        DoctorCard {
                            Text(prescription.notes)
                                .font(MedNexTheme.Typography.body)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, MedNexTheme.Spacing.md)
                    }
                }
                
                Spacer().frame(height: MedNexTheme.Spacing.xxl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .doctorFlowBackground()
    }
}
