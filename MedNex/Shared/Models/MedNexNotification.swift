//
//  MedNexNotification.swift
//  MedNex
//

import Foundation

struct MedNexNotification: Codable, Identifiable, Hashable {
    var id: String
    var userId: String
    var type: NotificationType
    var title: String
    var body: String
    var isRead: Bool
    var relatedId: String? // appointment, labTest, etc.
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, body
        case userId = "user_id"
        case isRead = "is_read"
        case relatedId = "related_id"
        case createdAt = "created_at"
    }
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        type: NotificationType = .general,
        title: String,
        body: String,
        isRead: Bool = false,
        relatedId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.body = body
        self.isRead = isRead
        self.relatedId = relatedId
        self.createdAt = createdAt
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case appointmentBooked = "appointment_booked"
    case appointmentReminder = "appointment_reminder"
    case appointmentCancelled = "appointment_cancelled"
    case labResultReady = "lab_result_ready"
    case prescriptionReady = "prescription_ready"
    case paymentDue = "payment_due"
    case shiftAssigned = "shift_assigned"
    case general
    
    var icon: String {
        switch self {
        case .appointmentBooked: return "calendar.badge.plus"
        case .appointmentReminder: return "bell.fill"
        case .appointmentCancelled: return "calendar.badge.minus"
        case .labResultReady: return "flask.fill"
        case .prescriptionReady: return "pills.fill"
        case .paymentDue: return "creditcard.fill"
        case .shiftAssigned: return "clock.fill"
        case .general: return "bell.fill"
        }
    }
}
