//
//  Patient.swift
//  MedNex
//

import Foundation

struct Patient: Codable, Identifiable, Hashable {
    var id: String
    var userId: String
    var personalInfo: PersonalInfo
    var emergencyContacts: [EmergencyContact]
    var medicalInfo: MedicalInfo
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case personalInfo = "personal_info"
        case emergencyContacts = "emergency_contacts"
        case medicalInfo = "medical_info"
    }
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        personalInfo: PersonalInfo,
        emergencyContacts: [EmergencyContact] = [],
        medicalInfo: MedicalInfo = MedicalInfo()
    ) {
        self.id = id
        self.userId = userId
        self.personalInfo = personalInfo
        self.emergencyContacts = emergencyContacts
        self.medicalInfo = medicalInfo
    }
}

struct PersonalInfo: Codable, Hashable {
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var gender: Gender
    var phone: String
    var address: String
    var city: String
    var state: String
    var zipCode: String
    
    enum CodingKeys: String, CodingKey {
        case phone, address, city, state, gender
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case zipCode = "zip_code"
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }
    
    init(
        firstName: String = "",
        lastName: String = "",
        dateOfBirth: Date = Date(),
        gender: Gender = .other,
        phone: String = "",
        address: String = "",
        city: String = "",
        state: String = "",
        zipCode: String = ""
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.phone = phone
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
    }
}

enum Gender: String, Codable, CaseIterable {
    case male, female, other
    
    var displayName: String {
        rawValue.capitalized
    }
}

struct EmergencyContact: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var relationship: String
    var phone: String
    
    init(id: String = UUID().uuidString, name: String = "", relationship: String = "", phone: String = "") {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.phone = phone
    }
}

struct MedicalInfo: Codable, Hashable {
    var bloodType: BloodType
    var allergies: [String]
    var chronicConditions: [String]
    var currentMedications: [String]
    var height: Double? // cm
    var weight: Double? // kg
    
    enum CodingKeys: String, CodingKey {
        case allergies, height, weight
        case bloodType = "blood_type"
        case chronicConditions = "chronic_conditions"
        case currentMedications = "current_medications"
    }
    
    init(
        bloodType: BloodType = .unknown,
        allergies: [String] = [],
        chronicConditions: [String] = [],
        currentMedications: [String] = [],
        height: Double? = nil,
        weight: Double? = nil
    ) {
        self.bloodType = bloodType
        self.allergies = allergies
        self.chronicConditions = chronicConditions
        self.currentMedications = currentMedications
        self.height = height
        self.weight = weight
    }
}

enum BloodType: String, Codable, CaseIterable {
    case aPositive = "A+"
    case aNegative = "A-"
    case bPositive = "B+"
    case bNegative = "B-"
    case abPositive = "AB+"
    case abNegative = "AB-"
    case oPositive = "O+"
    case oNegative = "O-"
    case unknown = "Unknown"
}
