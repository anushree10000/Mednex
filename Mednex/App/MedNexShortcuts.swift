//
//  MedNexShortcuts.swift
//  MedNex
//
//  Registers all MedNex App Shortcuts with Siri and Spotlight.
//  7 intents: 3 query-based + 4 actionable/conversational.

import AppIntents

struct MedNexShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // MARK: - Query Intents (Original)
        AppShortcut(
            intent: NextAppointmentIntent(),
            phrases: [
                "Show my next appointment in \(.applicationName)",
                "When is my next appointment in \(.applicationName)",
                "Next appointment in \(.applicationName)"
            ],
            shortTitle: "Next Appointment",
            systemImageName: "calendar.badge.clock"
        )
        
        AppShortcut(
            intent: TodayScheduleIntent(),
            phrases: [
                "Show today's schedule in \(.applicationName)",
                "What's on my schedule today in \(.applicationName)",
                "Today's appointments in \(.applicationName)"
            ],
            shortTitle: "Today's Schedule",
            systemImageName: "list.clipboard"
        )
        
        AppShortcut(
            intent: ActivePrescriptionsIntent(),
            phrases: [
                "Show my prescriptions in \(.applicationName)",
                "What medications am I taking in \(.applicationName)",
                "My active prescriptions in \(.applicationName)"
            ],
            shortTitle: "Active Prescriptions",
            systemImageName: "pills.fill"
        )
        
        // MARK: - Actionable Intents (New)
        AppShortcut(
            intent: BookAppointmentIntent(),
            phrases: [
                "Book an appointment in \(.applicationName)",
                "Schedule a doctor visit in \(.applicationName)",
                "I need to see a doctor in \(.applicationName)",
                "Make an appointment in \(.applicationName)"
            ],
            shortTitle: "Book Appointment",
            systemImageName: "calendar.badge.plus"
        )
        
        AppShortcut(
            intent: CheckBedAvailabilityIntent(),
            phrases: [
                "Check bed availability in \(.applicationName)",
                "How many beds are available in \(.applicationName)",
                "Show open beds in \(.applicationName)",
                "Bed status in \(.applicationName)"
            ],
            shortTitle: "Bed Availability",
            systemImageName: "bed.double.fill"
        )
        
        AppShortcut(
            intent: RequestLabTestIntent(),
            phrases: [
                "Request a lab test in \(.applicationName)",
                "Book a blood test in \(.applicationName)",
                "I need a lab test in \(.applicationName)",
                "Schedule lab work in \(.applicationName)"
            ],
            shortTitle: "Request Lab Test",
            systemImageName: "flask.fill"
        )
        
        AppShortcut(
            intent: VitalsUpdateIntent(),
            phrases: [
                "Log patient vitals in \(.applicationName)",
                "Record vitals in \(.applicationName)",
                "Update patient vitals in \(.applicationName)",
                "Enter vitals for a patient in \(.applicationName)"
            ],
            shortTitle: "Log Vitals",
            systemImageName: "waveform.path.ecg"
        )
    }
}
