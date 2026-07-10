//
//  TodayScheduleIntent.swift
//  MedNex
//
//  Siri App Intent: "Show today's schedule"
//  Role-aware: doctors see patient names, patients see doctor names.

import AppIntents
import SwiftUI

struct TodayScheduleIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Today's Schedule"
    static var description: IntentDescription = "Shows how many appointments are scheduled for today and their details."
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let appointments = await DataStore.shared.appointments
        let role = await DataStore.shared.activeUserRole
        let calendar = Calendar.current
        
        let todayAppointments = appointments
            .filter { calendar.isDateInToday($0.dateTime) && $0.status != .cancelled }
            .sorted { $0.dateTime < $1.dateTime }
        
        let isDoctor = role == .doctor
        
        if todayAppointments.isEmpty {
            return .result(
                dialog: "You have no appointments scheduled for today."
            ) {
                TodayScheduleSnippetView(appointments: [], isDoctor: false)
            }
        }
        
        let count = todayAppointments.count
        let noun = count == 1 ? "appointment" : "appointments"
        let roleContext = isDoctor ? "patient \(noun)" : "\(noun)"
        
        return .result(
            dialog: "You have \(count) \(roleContext) today."
        ) {
            TodayScheduleSnippetView(appointments: todayAppointments, isDoctor: isDoctor)
        }
    }
}

// MARK: - Siri Snippet View
struct TodayScheduleSnippetView: View {
    let appointments: [Appointment]
    let isDoctor: Bool
    
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
                            // Doctors see patient names, patients see doctor names
                            Text(isDoctor ? appt.patientName : appt.doctorName)
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
