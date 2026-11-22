//
//  Appointment.swift
//  MedNex
//

import Foundation

struct Appointment: Codable, Identifiable, Hashable {
    var id: String
    var patientId: String
    var patientName: String
    var doctorId: String
    var doctorName: String
    var specialty: MedicalSpecialty
    var dateTime: Date
    var endTime: Date
    var status: AppointmentStatus
    var type: AppointmentType
    var notes: String
    var prescriptionId: String?
    var billingStatus: BillingStatus
    var cancellationReason: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, specialty, status, type, notes
        case patientId = "patient_id"
        case patientName = "patient_name"
        case doctorId = "doctor_id"
        case doctorName = "doctor_name"
        case dateTime = "date_time"
        case endTime = "end_time"
        case prescriptionId = "prescription_id"
        case billingStatus = "billing_status"
        case cancellationReason = "cancellation_reason"
        case createdAt = "created_at"
    }
    
    init(
        id: String = UUID().uuidString,
        patientId: String,
        patientName: String = "",
        doctorId: String,
        doctorName: String = "",
        specialty: MedicalSpecialty = .generalMedicine,
        dateTime: Date = Date(),
        endTime: Date = Date().adding(hours: 1),
        status: AppointmentStatus = .scheduled,
        type: AppointmentType = .consultation,
        notes: String = "",
        prescriptionId: String? = nil,
        billingStatus: BillingStatus = .pending,
        cancellationReason: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.patientName = patientName
        self.doctorId = doctorId
        self.doctorName = doctorName
        self.specialty = specialty
        self.dateTime = dateTime
        self.endTime = endTime
        self.status = status
        self.type = type
        self.notes = notes
        self.prescriptionId = prescriptionId
        self.billingStatus = billingStatus
        self.cancellationReason = cancellationReason
        self.createdAt = createdAt
    }
    
    var canCancel: Bool {
        guard status == .scheduled else { return false }
        let hoursUntil = Calendar.current.dateComponents([.hour], from: Date(), to: dateTime).hour ?? 0
        return hoursUntil >= 4
    }
}

enum AppointmentStatus: String, Codable, CaseIterable {
    case scheduled
    case inProgress = "in_progress"
    case completed
    case cancelled
    case noShow = "no_show"
    
    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .noShow: return "No Show"
        }
    }
    
    var color: String {
        switch self {
        case .scheduled: return "3B82F6"
        case .inProgress: return "F59E0B"
        case .completed: return "10B981"
        case .cancelled: return "EF4444"
        case .noShow: return "6B7280"
        }
    }
}

enum AppointmentType: String, Codable, CaseIterable {
    case consultation
    case followUp = "follow_up"
    case emergency
    case checkup
    case procedure
    
    var displayName: String {
        switch self {
        case .consultation: return "Consultation"
        case .followUp: return "Follow-up"
        case .emergency: return "Emergency"
        case .checkup: return "Checkup"
        case .procedure: return "Procedure"
        }
    }
}

enum BillingStatus: String, Codable {
    case pending
    case invoiced
    case paid
    case partiallyPaid = "partially_paid"
    case overdue
    case waived
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .invoiced: return "Invoiced"
        case .paid: return "Paid"
        case .partiallyPaid: return "Partially Paid"
        case .overdue: return "Overdue"
        case .waived: return "Waived"
        }
    }
}
