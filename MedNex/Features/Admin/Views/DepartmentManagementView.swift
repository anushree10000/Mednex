//
//  DepartmentManagementView.swift
//  MedNex
//

import SwiftUI

struct DepartmentManagementView: View {
    @Environment(DataStore.self) private var dataStore
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: MedNexTheme.Spacing.md) {
                ForEach(dataStore.departments) { dept in
                    GlassCard {
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .foregroundStyle(MedNexTheme.Colors.primary)
                                    .frame(width: 44, height: 44)
                                    .background(MedNexTheme.Colors.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                
                                VStack(alignment: .leading) {
                                    Text(dept.name)
                                        .font(MedNexTheme.Typography.headline)
                                    Text(dept.description)
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                            
                            HStack(spacing: MedNexTheme.Spacing.lg) {
                                infoItem(icon: "person.fill", label: "Head", value: dept.headDoctorName ?? "Not Assigned")
                                Spacer()
                                infoItem(icon: "person.3.fill", label: "Staff", value: "\(dept.staffCount)")
                            }
                            
                            HStack(spacing: MedNexTheme.Spacing.lg) {
                                infoItem(icon: "mappin.circle.fill", label: "Location", value: dept.location)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Departments")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
    }
    
    private func infoItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: MedNexTheme.Spacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(MedNexTheme.Colors.primary)
                .font(.caption)
            VStack(alignment: .leading) {
                Text(label)
                    .font(MedNexTheme.Typography.caption2)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                Text(value)
                    .font(MedNexTheme.Typography.caption.weight(.medium))
            }
        }
    }
}
