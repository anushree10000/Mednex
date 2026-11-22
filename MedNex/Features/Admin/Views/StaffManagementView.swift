//
//  StaffManagementView.swift
//  MedNex
//

import SwiftUI

struct StaffManagementView: View {
    @State private var searchText = ""
    @State private var selectedRole: UserRole?
    @Environment(DataStore.self) private var dataStore
    
    var filteredStaff: [Staff] {
        var result = dataStore.staff
        if let role = selectedRole { result = result.filter { $0.role == role } }
        if !searchText.isEmpty { result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        return result
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.md) {
                MedNexSearchBar(text: $searchText, placeholder: "Search staff...")
                
                // Role filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MedNexTheme.Spacing.xs) {
                        roleChip(nil, label: "All")
                        ForEach(UserRole.allCases.filter { $0.isStaff }) { role in
                            roleChip(role, label: role.displayName)
                        }
                    }
                }
                
                // Staff List
                ForEach(filteredStaff) { member in
                    GlassCard {
                        HStack(spacing: MedNexTheme.Spacing.md) {
                            AvatarView(name: member.name, size: 48, backgroundColor: roleColor(member.role))
                            
                            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                                Text(member.name)
                                    .font(MedNexTheme.Typography.headline)
                                HStack(spacing: MedNexTheme.Spacing.sm) {
                                    StatusBadge(text: member.role.displayName, color: roleColor(member.role))
                                    StatusBadge(text: member.shift.rawValue, color: shiftColor(member.shift), icon: member.shift.icon)
                                }
                                Text(member.departmentName ?? "Unassigned")
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        }
                    }
                }
                
                // Doctors section
                SectionHeader(title: "Doctors (\(dataStore.doctors.count))")
                
                ForEach(dataStore.doctors) { doctor in
                    GlassCard {
                        HStack(spacing: MedNexTheme.Spacing.md) {
                            AvatarView(name: doctor.name, size: 48, backgroundColor: MedNexTheme.Colors.doctorTint)
                            
                            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                                Text(doctor.name)
                                    .font(MedNexTheme.Typography.headline)
                                Text(doctor.specialty.rawValue)
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundStyle(MedNexTheme.Colors.primary)
                                HStack(spacing: MedNexTheme.Spacing.sm) {
                                    Label("\(doctor.experience) yrs", systemImage: "briefcase.fill")
                                    Label(String(format: "%.1f", doctor.rating), systemImage: "star.fill")
                                        .foregroundStyle(MedNexTheme.Colors.accent)
                                }
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Staff Management")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
    }
    
    private func roleChip(_ role: UserRole?, label: String) -> some View {
        Button {
            HapticManager.selection()
            selectedRole = role
        } label: {
            Text(label)
                .font(MedNexTheme.Typography.caption.weight(.medium))
                .foregroundStyle(selectedRole == role ? .white : MedNexTheme.Colors.textPrimary)
                .padding(.horizontal, MedNexTheme.Spacing.sm)
                .padding(.vertical, MedNexTheme.Spacing.xs)
                .background(
                    selectedRole == role ? AnyShapeStyle(MedNexTheme.Colors.primary) : AnyShapeStyle(MedNexTheme.Colors.elevatedBackground),
                    in: Capsule()
                )
        }
    }
    
    private func roleColor(_ role: UserRole) -> Color {
        switch role {
        case .nurse: return MedNexTheme.Colors.nurseTint
        case .labTechnician: return MedNexTheme.Colors.labTechTint
        case .pharmacist: return MedNexTheme.Colors.pharmacistTint
        default: return MedNexTheme.Colors.primary
        }
    }
    
    private func shiftColor(_ shift: ShiftType) -> Color {
        switch shift {
        case .morning: return MedNexTheme.Colors.warning
        case .evening: return MedNexTheme.Colors.info
        case .night: return Color(hex: "6366F1")
        }
    }
}
