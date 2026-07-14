//
//  StaffDetailView.swift
//  MedNex
//
//  Staff detail — schedule is the focal point.
//  Simpler than doctor detail because there's less data.

import SwiftUI

struct StaffDetailView: View {
    let member: Staff
    @Environment(DataStore.self) private var dataStore
    
    var body: some View {
        List {
            // Profile
            AdminProfileHeader(
                name: member.name,
                imageURL: member.profileImageURL,
                subtitle: member.role.displayName,
                avatarColor: member.role == .nurse ? MedNexTheme.Colors.nurseTint : MedNexTheme.Colors.labTechTint
            )
            
            // Shift — the focal point, simple and clear
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(member.shift.rawValue)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(shiftColor)
                        Text(member.shift.timeRange)
                            .font(.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: member.shift.icon)
                        .font(.title)
                        .foregroundStyle(shiftColor)
                }
            }
            
            // Contact & details — plain rows, no icons on everything
            Section("Details") {
                AdminDetailRow(icon: "building.2.fill", label: "Department", value: member.departmentName ?? "Unassigned")
                AdminDetailRow(icon: "phone.fill", label: "Phone", value: member.phone.isEmpty ? "—" : member.phone)
                AdminDetailRow(icon: "envelope.fill", label: "Email", value: member.email.isEmpty ? "—" : member.email)
                
                HStack {
                    Text("Joined")
                        .font(.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    Spacer()
                    Text(member.joinDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                }
            }
            
            // Qualifications — just text, no icon header
            if !member.qualifications.isEmpty {
                Section("Qualifications") {
                    Text(member.qualifications)
                        .font(.body)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Staff")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var shiftColor: Color {
        switch member.shift {
        case .morning: return MedNexTheme.Colors.warning
        case .evening: return MedNexTheme.Colors.info
        case .night: return MedNexTheme.Colors.nightShiftTint
        }
    }
}
