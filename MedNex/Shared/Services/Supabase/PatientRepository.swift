#if canImport(Supabase)
//
//  PatientRepository.swift
//  MedNex
//
//  Data access layer for patient-related operations.

import Foundation
import Supabase
import PostgREST

final class PatientRepository: @unchecked Sendable {
    static let shared = PatientRepository()
    
    private let supabase = SupabaseService.shared
    private let log = LoggingService.shared
    
    private init() {}
    
    // MARK: - Patient Profile
    
    func fetchPatient(byUserId userId: String) async throws -> Patient {
        log.data("Fetching patient for user: \(userId)")
        return try await supabase.fetchSingle(from: "patients", id: userId)
    }
    
    func updatePatient(_ patient: Patient) async throws {
        try await supabase.update(patient, in: "patients", id: patient.id)
    }
    
    // MARK: - Appointments
    
    func fetchAppointments(patientId: String) async throws -> [Appointment] {
        try await supabase.fetch(
            from: "appointments",
            filters: [("patient_id", patientId)]
        )
    }
    
    func fetchUpcomingAppointments(patientId: String) async throws -> [Appointment] {
        log.data("Fetching upcoming appointments for patient: \(patientId)")
        let response: [Appointment] = try await supabase.client
            .from("appointments")
            .select()
            .eq("patient_id", value: patientId)
            .in("status", values: ["scheduled", "in_progress"])
            .order("date_time", ascending: true)
            .execute()
            .value
        return response
    }
    
    func cancelAppointment(id: String, reason: String) async throws {
        log.data("Cancelling appointment: \(id)")
        struct CancelUpdate: Encodable {
            let status: String
            let cancellation_reason: String
        }
        try await supabase.client
            .from("appointments")
            .update(CancelUpdate(status: "cancelled", cancellation_reason: reason))
            .eq("id", value: id)
            .execute()
    }
    
    func bookAppointment(_ appointment: Appointment) async throws {
        log.data("Booking appointment for patient: \(appointment.patientId)")
        try await supabase.insert(appointment, into: "appointments")
    }
    
    // MARK: - Prescriptions
    
    func fetchPrescriptions(patientId: String) async throws -> [Prescription] {
        try await supabase.fetch(
            from: "prescriptions",
            filters: [("patient_id", patientId)]
        )
    }
    
    // MARK: - Bills
    
    func fetchBills(patientId: String) async throws -> [Bill] {
        try await supabase.fetch(
            from: "bills",
            filters: [("patient_id", patientId)]
        )
    }
    
    func fetchUnpaidBills(patientId: String) async throws -> [Bill] {
        let response: [Bill] = try await supabase.client
            .from("bills")
            .select()
            .eq("patient_id", value: patientId)
            .in("status", values: ["unpaid", "partial", "overdue"])
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    // MARK: - Lab Tests
    
    func fetchLabTests(patientId: String) async throws -> [LabTest] {
        try await supabase.fetch(
            from: "lab_tests",
            filters: [("patient_id", patientId)]
        )
    }
    
    // MARK: - Vitals
    
    func fetchVitalRecords(patientId: String, limit: Int = 14) async throws -> [VitalRecord] {
        log.data("Fetching vitals for patient: \(patientId)")
        let response: [VitalRecord] = try await supabase.client
            .from("vital_records")
            .select()
            .eq("patient_id", value: patientId)
            .order("timestamp", ascending: false)
            .limit(limit)
            .execute()
            .value
        return response
    }
    
    // MARK: - Notifications
    
    func fetchNotifications(userId: String) async throws -> [MedNexNotification] {
        let response: [MedNexNotification] = try await supabase.client
            .from("notifications")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value
        return response
    }
    
    func markNotificationRead(id: String) async throws {
        struct ReadUpdate: Encodable {
            let is_read: Bool
        }
        try await supabase.client
            .from("notifications")
            .update(ReadUpdate(is_read: true))
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Doctors List (for booking)
    
    func fetchAvailableDoctors(specialty: String? = nil) async throws -> [Doctor] {
        var query = supabase.client
            .from("doctors")
            .select()
            .eq("is_available", value: true)
        
        if let specialty {
            query = query.eq("specialty", value: specialty)
        }
        
        let response: [Doctor] = try await query
            .order("rating", ascending: false)
            .execute()
            .value
        return response
    }
    
    // MARK: - Chat Sessions
    
    func fetchChatSessions(patientId: String) async throws -> [ChatSession] {
        try await supabase.fetch(
            from: "chat_sessions",
            filters: [("patient_id", patientId)]
        )
    }
    
    func createChatSession(_ session: ChatSession) async throws {
        try await supabase.insert(session, into: "chat_sessions")
    }
    
    func saveChatMessage(_ message: ChatMessage, sessionId: String) async throws {
        struct ChatMessageRow: Encodable {
            let id: String
            let session_id: String
            let role: String
            let content: String
            let timestamp: Date
            let suggested_specialty: String?
            let urgency_level: String?
        }
        
        let row = ChatMessageRow(
            id: message.id,
            session_id: sessionId,
            role: message.role.rawValue,
            content: message.content,
            timestamp: message.timestamp,
            suggested_specialty: message.suggestedSpecialty?.rawValue,
            urgency_level: message.urgencyLevel?.rawValue
        )
        
        try await supabase.insert(row, into: "chat_messages")
    }
}
#endif
