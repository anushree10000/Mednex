//
//  BookAppointmentIntent.swift
//  MedNex
//
//  Siri App Intent: "Book an appointment in MedNex"
//  Conversational intent that lets patients book appointments via Siri.

import AppIntents
import SwiftUI

struct BookAppointmentIntent: AppIntent {
    static var title: LocalizedStringResource = "Book Appointment"
    static var description: IntentDescription = "Book a doctor's appointment by specifying specialty and preferred date."
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Specialty")
    var specialty: String?
    
    @Parameter(title: "Preferred Date")
    var preferredDate: Date?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Book a \(\.$specialty) appointment on \(\.$preferredDate)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let specialtyName = specialty ?? "General Medicine"
        let date = preferredDate ?? Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: date)
        
        // Simulate picking an available doctor
        let doctors = await MainActor.run { DataStore.shared.doctors }
        let matchedDoctor = doctors.first { $0.specialty.rawValue.lowercased().contains(specialtyName.lowercased()) } ?? doctors.first!
        
        return .result(
            dialog: "I've booked a \(specialtyName) appointment with \(matchedDoctor.name) on \(dateString). You'll receive a confirmation notification."
        ) {
            BookAppointmentSnippetView(
                doctorName: matchedDoctor.name,
                specialty: specialtyName,
                date: date
            )
        }
    }
}

struct BookAppointmentSnippetView: View {
    let doctorName: String
    let specialty: String
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundStyle(.green)
                Text("Appointment Booked")
                    .font(.headline)
            }
            
            Divider()
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(doctorName)
                        .font(.subheadline.weight(.semibold))
                    Text(specialty)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline.weight(.medium))
                    Text(date.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text("Confirmation sent to your notifications")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
