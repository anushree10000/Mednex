#if canImport(Supabase)
//
//  DoctorRepository.swift
//  MedNex
//
//  Data access layer for doctor-related operations.

import Foundation
import Supabase
import PostgREST

final class DoctorRepository: @unchecked Sendable {
    static let shared = DoctorRepository()
    
    private let supabase = SupabaseService.shared
    private let log = LoggingService.shared
    
    private init() {}
    
    // MARK: - Doctor Profile
    
    func fetchDoctor(byUserId userId: String) async throws -> Doctor {
        log.data("Fetching doctor for user: \(userId)")
        let response: Doctor = try await supabase.client
            .from("doctors")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        return response
    }
    
    func updateDoctor(_ doctor: Doctor) async throws {
        try await supabase.update(doctor, in: "doctors", id: doctor.id)
    }
    
    // MARK: - Schedule & Time Slots
    
    func fetchTimeSlots(doctorId: String, date: Date? = nil) async throws -> [TimeSlot] {
        var query = supabase.client
            .from("time_slots")
            .select()
            .eq("doctor_id", value: doctorId)
        
        if let date {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            let dateStr = formatter.string(from: date)
            query = query.eq("date", value: dateStr)
        }
        
        let response: [TimeSlot] = try await query
            .order("start_time", ascending: true)
            .execute()
            .value
        return response
    }
    
    func updateTimeSlot(_ slot: TimeSlot) async throws {
        try await supabase.update(slot, in: "time_slots", id: slot.id)
    }
    
    // MARK: - Appointments
    
    func fetchAppointments(doctorId: String) async throws -> [Appointment] {
        try await supabase.fetch(
            from: "appointments",
            filters: [("doctor_id", doctorId)]
        )
    }
    
    func fetchTodayAppointments(doctorId: String) async throws -> [Appointment] {
        log.data("Fetching today's appointments for doctor: \(doctorId)")
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let formatter = ISO8601DateFormatter()
        
        let response: [Appointment] = try await supabase.client
            .from("appointments")
            .select()
            .eq("doctor_id", value: doctorId)
            .gte("date_time", value: formatter.string(from: startOfDay))
            .lt("date_time", value: formatter.string(from: endOfDay))
            .order("date_time", ascending: true)
            .execute()
            .value
        return response
    }
    
    func updateAppointmentStatus(id: String, status: AppointmentStatus) async throws {
        struct StatusUpdate: Encodable {
            let status: String
        }
        try await supabase.client
            .from("appointments")
            .update(StatusUpdate(status: status.rawValue))
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Patients
    
    func fetchDoctorPatients(doctorId: String) async throws -> [Patient] {
        log.data("Fetching patients for doctor: \(doctorId)")
        // Get distinct patients from appointments
        let appointments: [Appointment] = try await supabase.client
            .from("appointments")
            .select()
            .eq("doctor_id", value: doctorId)
            .execute()
            .value
        
        let patientIds = Array(Set(appointments.map(\.patientId)))
        
        guard !patientIds.isEmpty else { return [] }
        
        let patients: [Patient] = try await supabase.client
            .from("patients")
            .select()
            .in("id", values: patientIds)
            .execute()
            .value
        return patients
    }
    
    // MARK: - Prescriptions
    
    func createPrescription(_ prescription: Prescription) async throws {
        log.data("Creating prescription for patient: \(prescription.patientId)")
        try await supabase.insert(prescription, into: "prescriptions")
        
        // Insert prescribed medicines
        for medicine in prescription.medicines {
            struct MedicineRow: Encodable {
                let id: String
                let prescription_id: String
                let name: String
                let dosage: String
                let frequency: String
                let duration: String
                let instructions: String
                let is_taken: Bool
            }
            
            let row = MedicineRow(
                id: medicine.id,
                prescription_id: prescription.id,
                name: medicine.name,
                dosage: medicine.dosage,
                frequency: medicine.frequency.rawValue,
                duration: medicine.duration,
                instructions: medicine.instructions,
                is_taken: medicine.isTaken
            )
            try await supabase.insert(row, into: "prescribed_medicines")
        }
    }
    
    func fetchPrescriptions(doctorId: String) async throws -> [Prescription] {
        try await supabase.fetch(
            from: "prescriptions",
            filters: [("doctor_id", doctorId)]
        )
    }
    
    // MARK: - Lab Orders
    
    func createLabOrder(_ labTest: LabTest) async throws {
        log.data("Creating lab order: \(labTest.testName)")
        try await supabase.insert(labTest, into: "lab_tests")
    }
    
    func fetchLabOrders(doctorId: String) async throws -> [LabTest] {
        try await supabase.fetch(
            from: "lab_tests",
            filters: [("doctor_id", doctorId)]
        )
    }
    
    // MARK: - Medical Records / Vitals
    
    func addVitalRecord(_ record: VitalRecord) async throws {
        try await supabase.insert(record, into: "vital_records")
    }
    
    func fetchPatientVitals(patientId: String) async throws -> [VitalRecord] {
        let response: [VitalRecord] = try await supabase.client
            .from("vital_records")
            .select()
            .eq("patient_id", value: patientId)
            .order("timestamp", ascending: false)
            .limit(30)
            .execute()
            .value
        return response
    }
}
#endif
