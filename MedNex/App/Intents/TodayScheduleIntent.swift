//
//  TodayScheduleIntent.swift
//  MedNex
//
//  Siri App Intent: "Show today's schedule"
//  Perfect for doctors checking their day at a glance, hands-free.

import AppIntents
import SwiftUI

struct TodayScheduleIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Today's Schedule"
    static var description: IntentDescription = "Shows how many appointments are scheduled for today and their details."
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let appointments = DataStore.shared.appointments
        let calendar = Calendar.current
        
        let todayAppointments = appointments
            .filter { calendar.isDateInToday($0.dateTime) && $0.status != .cancelled }
            .sorted { $0.dateTime < $1.dateTime }
        
        if todayAppointments.isEmpty {
            return .result(
                dialog: "You have no appointments scheduled for today."
            ) {
                TodayScheduleSnippetView(appointments: [])
            }
        }
        
        let count = todayAppointments.count
        let noun = count == 1 ? "appointment" : "appointments"
        
        return .result(
            dialog: "You have \(count) \(noun) today."
        ) {
            TodayScheduleSnippetView(appointments: todayAppointments)
        }
    }
}

// MARK: - Siri Snippet View
struct TodayScheduleSnippetView: View {
    let appointments: [Appointment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "list.clipboard")
                    .foregroundStyle(.green)
                Text("Today's Schedule")
                    .font(.headline)
                Spacer()
                Text("\(appointments.count)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.green)
            }
            
            if appointments.isEmpty {
                Text("No appointments today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                Divider()
                
                ForEach(appointments.prefix(5)) { appt in
                    HStack {
                        Text(appt.dateTime.formatted(date: .omitted, time: .shortened))
                            .font(.caption.weight(.medium).monospacedDigit())
                            .frame(width: 60, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(appt.patientName.isEmpty ? appt.doctorName : appt.patientName)
                                .font(.subheadline.weight(.medium))
                            Text(appt.specialty.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(appt.status.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                }
                
                if appointments.count > 5 {
                    Text("+ \(appointments.count - 5) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
