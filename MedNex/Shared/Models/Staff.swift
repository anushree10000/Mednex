//
//  Staff.swift
//  MedNex
//

import Foundation

struct Staff: Codable, Identifiable, Hashable {
    var id: String
    var userId: String
    var name: String
    var role: UserRole
    var departmentId: String?
    var departmentName: String?
    var phone: String
    var email: String
    var shift: ShiftType
    var joinDate: Date
    var isActive: Bool
    var qualifications: String
    var specialization: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, role, phone, email, shift, qualifications, specialization
        case userId = "user_id"
        case departmentId = "department_id"
        case departmentName = "department_name"
        case joinDate = "join_date"
        case isActive = "is_active"
    }
    
    init(
        id: String = UUID().uuidString,
        userId: String = "",
        name: String,
        role: UserRole = .nurse,
        departmentId: String? = nil,
        departmentName: String? = nil,
        phone: String = "",
        email: String = "",
        shift: ShiftType = .morning,
        joinDate: Date = Date(),
        isActive: Bool = true,
        qualifications: String = "",
        specialization: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.role = role
        self.departmentId = departmentId
        self.departmentName = departmentName
        self.phone = phone
        self.email = email
        self.shift = shift
        self.joinDate = joinDate
        self.isActive = isActive
        self.qualifications = qualifications
        self.specialization = specialization
    }
}

enum ShiftType: String, Codable, CaseIterable {
    case morning = "Morning"
    case evening = "Evening"
    case night = "Night"
    
    var timeRange: String {
        switch self {
        case .morning: return "6:00 AM – 2:00 PM"
        case .evening: return "2:00 PM – 10:00 PM"
        case .night: return "10:00 PM – 6:00 AM"
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .evening: return "sun.haze.fill"
        case .night: return "moon.fill"
        }
    }
}
