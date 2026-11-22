//
//  InventoryItem.swift
//  MedNex
//

import Foundation

struct InventoryItem: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var category: InventoryCategory
    var stock: Int
    var reorderLevel: Int
    var unitPrice: Double
    var supplier: String
    var lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, category, stock, supplier
        case reorderLevel = "reorder_level"
        case unitPrice = "unit_price"
        case lastUpdated = "last_updated"
    }
    
    init(
        id: String = UUID().uuidString,
        name: String,
        category: InventoryCategory = .medication,
        stock: Int = 0,
        reorderLevel: Int = 10,
        unitPrice: Double = 0,
        supplier: String = "",
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.stock = stock
        self.reorderLevel = reorderLevel
        self.unitPrice = unitPrice
        self.supplier = supplier
        self.lastUpdated = lastUpdated
    }
    
    var isLowStock: Bool {
        stock <= reorderLevel
    }
}

enum InventoryCategory: String, Codable, CaseIterable {
    case medication = "Medication"
    case equipment = "Equipment"
    case consumables = "Consumables"
    case labSupplies = "Lab Supplies"
    case surgical = "Surgical"
    case other = "Other"
}
