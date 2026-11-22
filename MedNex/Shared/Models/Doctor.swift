//
//  Doctor.swift
//  MedNex
//

import Foundation

struct Doctor: Codable, Identifiable, Hashable {
    var id: String
    var userId: String
    var name: String
    var specialty: MedicalSpecialty
    var experience: Int // years
    var licenseNumber: String
    var consultationFee: Double
    var departmentId: String?
    var rating: Double
    var totalRatings: Int
    var availableSlots: [TimeSlot]
    var bio: String
    var education: String
    var languages: [String]
    var isAvailable: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, specialty, experience, rating, bio, education, languages
        case userId = "user_id"
        case licenseNumber = "license_number"
        case consultationFee = "consultation_fee"
        case departmentId = "department_id"
        case totalRatings = "total_ratings"
        case availableSlots = "available_slots"
        case isAvailable = "is_available"
    }
    
    init(
        id: String = UUID().uuidString,
        userId: String = "",
        name: String,
        specialty: MedicalSpecialty = .generalMedicine,
        experience: Int = 0,
        licenseNumber: String = "",
        consultationFee: Double = 500,
        departmentId: String? = nil,
        rating: Double = 4.5,
        totalRatings: Int = 0,
        availableSlots: [TimeSlot] = [],
        bio: String = "",
        education: String = "",
        languages: [String] = ["English"],
        isAvailable: Bool = true
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.specialty = specialty
        self.experience = experience
        self.licenseNumber = licenseNumber
        self.consultationFee = consultationFee
        self.departmentId = departmentId
        self.rating = rating
        self.totalRatings = totalRatings
        self.availableSlots = availableSlots
        self.bio = bio
        self.education = education
        self.languages = languages
        self.isAvailable = isAvailable
    }
}

enum MedicalSpecialty: String, Codable, CaseIterable, Identifiable {
    case generalMedicine = "General Medicine"
    case cardiology = "Cardiology"
    case dermatology = "Dermatology"
    case orthopedics = "Orthopedics"
    case pediatrics = "Pediatrics"
    case neurology = "Neurology"
    case gynecology = "Gynecology"
    case ophthalmology = "Ophthalmology"
    case ent = "ENT"
    case psychiatry = "Psychiatry"
    case urology = "Urology"
    case gastroenterology = "Gastroenterology"
    case pulmonology = "Pulmonology"
    case endocrinology = "Endocrinology"
    case oncology = "Oncology"
    case radiology = "Radiology"
    case anesthesiology = "Anesthesiology"
    case emergencyMedicine = "Emergency Medicine"
    
    var id: String { rawValue }
    
    // Custom decoder: handles both "General Medicine" and "general_medicine"
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        // Try exact match first
        if let specialty = MedicalSpecialty(rawValue: value) {
            self = specialty
            return
        }
        
        // Try snake_case → Title Case mapping
        let normalized = value
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
        if let specialty = MedicalSpecialty(rawValue: normalized) {
            self = specialty
            return
        }
        
        // Case-insensitive fallback
        if let specialty = MedicalSpecialty.allCases.first(where: {
            $0.rawValue.lowercased() == value.lowercased()
        }) {
            self = specialty
            return
        }
        
        // Default rather than crash
        self = .generalMedicine
    }
    
    var icon: String {
        switch self {
        case .cardiology: return "heart.fill"
        case .dermatology: return "hand.raised.fill"
        case .orthopedics: return "figure.walk"
        case .pediatrics: return "figure.and.child.holdinghands"
        case .neurology: return "brain.head.profile"
        case .gynecology: return "person.fill"
        case .ophthalmology: return "eye.fill"
        case .ent: return "ear.fill"
        case .psychiatry: return "brain.fill"
        case .oncology: return "cross.vial.fill"
        case .pulmonology: return "lungs.fill"
        default: return "stethoscope"
        }
    }
}

struct TimeSlot: Codable, Identifiable, Hashable {
    var id: String
    var date: Date
    var startTime: Date
    var endTime: Date
    var isBooked: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, date
        case startTime = "start_time"
        case endTime = "end_time"
        case isBooked = "is_booked"
    }
    
    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        startTime: Date = Date(),
        endTime: Date = Date(),
        isBooked: Bool = false
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.isBooked = isBooked
    }
}
