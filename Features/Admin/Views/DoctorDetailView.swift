//
//  DoctorDetailView.swift
//  MedNex
//
//  Doctor detail — profile-led. Stats are inline text, not cards.
//  Appointments are a plain list. Bio is prose, not a boxed section.

import SwiftUI

struct DoctorDetailView: View {
    let doctor: Doctor
    @Environment(DataStore.self) private var dataStore
    
    private var departmentName: String {
        if let deptId = doctor.departmentId {
            return dataStore.departments.first(where: { $0.id == deptId })?.name ?? "Unknown"
        }
        return "Unassigned"
    }
    
    private var doctorAppointments: [Appointment] {
        dataStore.appointments
            .filter { $0.doctorId == doctor.id || $0.doctorId == doctor.userId }
            .sorted { $0.dateTime > $1.dateTime }
    }
    
    var body: some View {
        List {
            // Profile — the hero
            AdminProfileHeader(
                name: doctor.name,
                imageURL: doctor.profileImageURL,
                subtitle: doctor.specialty.rawValue,
                avatarColor: MedNexTheme.Colors.doctorTint
            )
            
            // Core stats — inline, not cards. Just text.
            Section {
                HStack {
                    statPill(icon: "star.fill", value: String(format: "%.1f", doctor.rating), color: MedNexTheme.Colors.accent)
                    Spacer()
                    Text("\(doctor.experience) yrs exp")
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    Spacer()
                    Text("₹\(Int(doctor.consultationFee))/visit")
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
                .font(.subheadline)
            }
            
            // Professional info — uses AdminDetailRow where structured data helps
            Section("Professional") {
                AdminDetailRow(icon: "building.2.fill", label: "Department", value: departmentName)
                AdminDetailRow(icon: "number", label: "License", value: doctor.licenseNumber.isEmpty ? "—" : doctor.licenseNumber)
                
                if !doctor.languages.isEmpty {
                    AdminDetailRow(icon: "globe", label: "Languages", value: doctor.languages.joined(separator: ", "))
                }
                
                HStack {
                    Circle()
                        .fill(doctor.isAvailable ? MedNexTheme.Colors.success : MedNexTheme.Colors.error)
                        .frame(width: 8, height: 8)
                    Text(doctor.isAvailable ? "Available" : "Unavailable")
                        .font(.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
            }
            
            // Bio — just prose, no icon header
            if !doctor.bio.isEmpty {
                Section {
                    Text(doctor.bio)
                        .font(.body)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
            }
            
            // Appointments — plain list
            Section(doctorAppointments.isEmpty ? "No Appointments" : "Appointments · \(doctorAppointments.count)") {
                ForEach(doctorAppointments.prefix(10)) { appt in
                    AdminAppointmentRow(title: appt.patientName, date: appt.dateTime, status: appt.status)
                }
                
                if doctorAppointments.count > 10 {
                    Text("\(doctorAppointments.count - 10) more")
                        .font(.caption)
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Doctor")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func statPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .fontWeight(.semibold)
        }
    }
}
