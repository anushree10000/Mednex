//
//  InventoryRequest.swift
//  MedNex
//
//  Created by Abhishek on 13/03/26.
//

import Foundation

struct InventoryRequest: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var itemName: String
    var quantity: Int
    var unit: RequestUnit
    var priority: RequestPriority
    var notes: String
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
