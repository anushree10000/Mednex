//
//  Department.swift
//  MedNex
//

import Foundation

struct Department: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var headDoctorId: String?
    var headDoctorName: String?
    var staffCount: Int
    var location: String
    var description: String
    var isActive: Bool
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, location, description
        case headDoctorId = "head_doctor_id"
        case headDoctorName = "head_doctor_name"
        case staffCount = "staff_count"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
    
    init(
        id: String = UUID().uuidString,
        name: String,
        headDoctorId: String? = nil,
        headDoctorName: String? = nil,
        staffCount: Int = 0,
        location: String = "",
        description: String = "",
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.headDoctorId = headDoctorId
        self.headDoctorName = headDoctorName
        self.staffCount = staffCount
        self.location = location
        self.description = description
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
