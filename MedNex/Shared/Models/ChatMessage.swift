//
//  ChatMessage.swift
//  MedNex
//

import Foundation

struct ChatSession: Codable, Identifiable, Hashable {
    var id: String
    var patientId: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, messages
        case patientId = "patient_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: String = UUID().uuidString,
        patientId: String,
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct ChatMessage: Codable, Identifiable, Hashable {
    var id: String
    var role: ChatRole
    var content: String
    var timestamp: Date
    var suggestedSpecialty: MedicalSpecialty?
    var urgencyLevel: UrgencyLevel?
    
    enum CodingKeys: String, CodingKey {
        case id, role, content, timestamp
        case suggestedSpecialty = "suggested_specialty"
        case urgencyLevel = "urgency_level"
    }
    
    init(
        id: String = UUID().uuidString,
        role: ChatRole,
        content: String,
        timestamp: Date = Date(),
        suggestedSpecialty: MedicalSpecialty? = nil,
        urgencyLevel: UrgencyLevel? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.suggestedSpecialty = suggestedSpecialty
        self.urgencyLevel = urgencyLevel
    }
}

enum ChatRole: String, Codable {
    case user
    case assistant
    case system
}

enum UrgencyLevel: String, Codable, CaseIterable {
    case low
    case moderate
    case high
    case emergency
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .low: return "10B981"
        case .moderate: return "F59E0B"
        case .high: return "F97316"
        case .emergency: return "EF4444"
        }
    }
}
