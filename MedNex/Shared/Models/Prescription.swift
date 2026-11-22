//
//  Prescription.swift
//  MedNex
//

import Foundation

struct Prescription: Codable, Identifiable, Hashable {
    var id: String
    var appointmentId: String
    var patientId: String
    var patientName: String
    var doctorId: String
    var doctorName: String
    var medicines: [PrescribedMedicine]
    var diagnosis: String
    var notes: String
    var pdfURL: String?
    var status: PrescriptionStatus
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, medicines, diagnosis, notes, status
        case appointmentId = "appointment_id"
        case patientId = "patient_id"
        case patientName = "patient_name"
        case doctorId = "doctor_id"
        case doctorName = "doctor_name"
        case pdfURL = "pdf_url"
        case createdAt = "created_at"
    }
    
    init(
        id: String = UUID().uuidString,
        appointmentId: String = "",
        patientId: String,
        patientName: String = "",
        doctorId: String,
        doctorName: String = "",
        medicines: [PrescribedMedicine] = [],
        diagnosis: String = "",
        notes: String = "",
        pdfURL: String? = nil,
        status: PrescriptionStatus = .active,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.appointmentId = appointmentId
        self.patientId = patientId
        self.patientName = patientName
        self.doctorId = doctorId
        self.doctorName = doctorName
        self.medicines = medicines
        self.diagnosis = diagnosis
        self.notes = notes
        self.pdfURL = pdfURL
        self.status = status
        self.createdAt = createdAt
    }
}

struct PrescribedMedicine: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var dosage: String
    var frequency: MedicineFrequency
    var duration: String
    var instructions: String
    var isTaken: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, dosage, frequency, duration, instructions
        case isTaken = "is_taken"
    }
    
    init(
        id: String = UUID().uuidString,
        name: String = "",
        dosage: String = "",
        frequency: MedicineFrequency = .onceDaily,
        duration: String = "",
        instructions: String = "",
        isTaken: Bool = false
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.duration = duration
        self.instructions = instructions
        self.isTaken = isTaken
    }
}

enum MedicineFrequency: String, Codable, CaseIterable {
    case onceDaily = "Once Daily"
    case twiceDaily = "Twice Daily"
    case thriceDaily = "Thrice Daily"
    case fourTimesDaily = "Four Times Daily"
    case asNeeded = "As Needed"
    case weekly = "Weekly"
    case beforeMeals = "Before Meals"
    case afterMeals = "After Meals"
    case bedtime = "At Bedtime"
}

enum PrescriptionStatus: String, Codable {
    case active
    case completed
    case dispensed
    case partiallyDispensed = "partially_dispensed"
    case cancelled
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .dispensed: return "Dispensed"
        case .partiallyDispensed: return "Partially Dispensed"
        case .cancelled: return "Cancelled"
        }
    }
}

struct Medicine: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var genericName: String
    var category: String
    var manufacturer: String
    var dosageForms: [String]
    var strengths: [String]
    
    init(
        id: String = UUID().uuidString,
        name: String,
        genericName: String = "",
        category: String = "",
        manufacturer: String = "",
        dosageForms: [String] = [],
        strengths: [String] = []
    ) {
        self.id = id
        self.name = name
        self.genericName = genericName
        self.category = category
        self.manufacturer = manufacturer
        self.dosageForms = dosageForms
        self.strengths = strengths
    }
}
