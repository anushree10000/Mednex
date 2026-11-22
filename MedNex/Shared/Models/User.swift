//
//  User.swift
//  MedNex
//

import Foundation

// MARK: - User Role
enum UserRole: String, Codable, CaseIterable, Identifiable {
    case patient
    case doctor
    case admin
    case nurse
    case labTechnician = "lab_technician"
    case pharmacist
    case receptionist
    case accountant
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .patient: return "Patient"
        case .doctor: return "Doctor"
        case .admin: return "Admin"
        case .nurse: return "Nurse"
        case .labTechnician: return "Lab Technician"
        case .pharmacist: return "Pharmacist"
        case .receptionist: return "Receptionist"
        case .accountant: return "Accountant"
        }
    }
    
    var icon: String {
        switch self {
        case .patient: return "person.fill"
        case .doctor: return "stethoscope"
        case .admin: return "shield.checkered"
        case .nurse: return "cross.case.fill"
        case .labTechnician: return "flask.fill"
        case .pharmacist: return "pills.fill"
        case .receptionist: return "person.crop.rectangle.fill"
        case .accountant: return "banknote.fill"
        }
    }
    
    var isStaff: Bool {
        self != .patient
    }
}

// MARK: - User
struct MedNexUser: Codable, Identifiable, Hashable {
    var id: String
    var email: String
    var role: UserRole
    var displayName: String
    var profileImageURL: String?
    var phoneNumber: String?
    var createdAt: Date
    var lastLogin: Date
    var isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, email, role
        case displayName = "display_name"
        case profileImageURL = "profile_image_url"
        case phoneNumber = "phone_number"
        case createdAt = "created_at"
        case lastLogin = "last_login"
        case isActive = "is_active"
    }
    
    init(
        id: String = UUID().uuidString,
        email: String,
        role: UserRole,
        displayName: String,
        profileImageURL: String? = nil,
        phoneNumber: String? = nil,
        createdAt: Date = Date(),
        lastLogin: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.email = email
        self.role = role
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.phoneNumber = phoneNumber
        self.createdAt = createdAt
        self.lastLogin = lastLogin
        self.isActive = isActive
    }
}
