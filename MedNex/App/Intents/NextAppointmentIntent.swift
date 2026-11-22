//
//  NextAppointmentIntent.swift
//  MedNex
//
//  Siri App Intent: "Show my next appointment"
//  Provides hands-free access to upcoming appointment details.

import AppIntents
import SwiftUI

struct NextAppointmentIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Next Appointment"
    static var description: IntentDescription = "Shows your next upcoming appointment with doctor name, date, and time."
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let appointments = DataStore.shared.appointments
        let now = Date()
        
        let upcoming = appointments
            .filter { $0.status == .scheduled && $0.dateTime > now }
            .sorted { $0.dateTime < $1.dateTime }
        
        guard let next = upcoming.first else {
            return .result(
                dialog: "You don't have any upcoming appointments scheduled."
            ) {
                NextAppointmentSnippetView(appointment: nil)
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: next.dateTime)
        
        return .result(
            dialog: "Your next appointment is with \(next.doctorName) on \(dateString) for \(next.specialty.rawValue)."
        ) {
            NextAppointmentSnippetView(appointment: next)
        }
    }
}

// MARK: - Siri Snippet View
struct NextAppointmentSnippetView: View {
    let appointment: Appointment?
    
    var body: some View {
        if let appt = appointment {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.blue)
                    Text("Next Appointment")
                        .font(.headline)
                }
                
                Divider()
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appt.doctorName)
                            .font(.subheadline.weight(.semibold))
                        Text(appt.specialty.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(appt.dateTime.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.weight(.medium))
                        Text(appt.dateTime.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: "stethoscope")
                        .font(.caption)
                    Text(appt.type.displayName)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            VStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No upcoming appointments")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
