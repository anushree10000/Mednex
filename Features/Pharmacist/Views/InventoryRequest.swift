//
//  InventoryRequest.swift
//  MedNex
//
//  Created by Abhishek on 13/03/26.
//

import Foundation

struct InventoryRequest: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var pharmacistId: String = ""
    var itemName: String
    var quantity: Int
    var unit: RequestUnit
    var priority: RequestPriority
    var notes: String
    var status: RequestStatus = .pending
    var createdAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case pharmacistId = "pharmacist_id"
        case itemName = "item_name"
        case quantity, unit, priority, notes, status
        case createdAt = "created_at"
    }
}

enum RequestPriority: String, CaseIterable, Codable {
    case normal = "Normal"
    case urgent = "Urgent"
}

enum RequestUnit: String, CaseIterable, Codable {
    case packs = "Packs"
    case boxes = "Boxes"
    case bottles = "Bottles"
    case units = "Units"
}

enum RequestStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
    case fulfilled = "Fulfilled"
    
    var displayName: String { rawValue }
}
