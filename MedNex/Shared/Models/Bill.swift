//
//  Bill.swift
//  MedNex
//

import Foundation

struct Bill: Codable, Identifiable, Hashable {
    var id: String
    var appointmentId: String
    var patientId: String
    var patientName: String
    var items: [BillItem]
    var totalAmount: Double
    var paidAmount: Double
    var paymentMode: PaymentMode?
    var status: BillStatus
    var invoicePDFURL: String?
    var createdAt: Date
    var paidAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, items, status
        case appointmentId = "appointment_id"
        case patientId = "patient_id"
        case patientName = "patient_name"
        case totalAmount = "total_amount"
        case paidAmount = "paid_amount"
        case paymentMode = "payment_mode"
        case invoicePDFURL = "invoice_pdf_url"
        case createdAt = "created_at"
        case paidAt = "paid_at"
    }
    
    init(
        id: String = UUID().uuidString,
        appointmentId: String = "",
        patientId: String,
        patientName: String = "",
        items: [BillItem] = [],
        totalAmount: Double = 0,
        paidAmount: Double = 0,
        paymentMode: PaymentMode? = nil,
        status: BillStatus = .unpaid,
        invoicePDFURL: String? = nil,
        createdAt: Date = Date(),
        paidAt: Date? = nil
    ) {
        self.id = id
        self.appointmentId = appointmentId
        self.patientId = patientId
        self.patientName = patientName
        self.items = items
        self.totalAmount = totalAmount
        self.paidAmount = paidAmount
        self.paymentMode = paymentMode
        self.status = status
        self.invoicePDFURL = invoicePDFURL
        self.createdAt = createdAt
        self.paidAt = paidAt
    }
    
    var balanceDue: Double {
        totalAmount - paidAmount
    }
}

struct BillItem: Codable, Identifiable, Hashable {
    var id: String
    var description: String
    var quantity: Int
    var unitPrice: Double
    var total: Double
    
    enum CodingKeys: String, CodingKey {
        case id, description, quantity, total
        case unitPrice = "unit_price"
    }
    
    init(
        id: String = UUID().uuidString,
        description: String = "",
        quantity: Int = 1,
        unitPrice: Double = 0,
        total: Double = 0
    ) {
        self.id = id
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.total = total
    }
}

enum BillStatus: String, Codable, CaseIterable {
    case unpaid
    case paid
    case partial
    case overdue
    case waived
    
    var displayName: String {
        switch self {
        case .unpaid: return "Unpaid"
        case .paid: return "Paid"
        case .partial: return "Partial"
        case .overdue: return "Overdue"
        case .waived: return "Waived"
        }
    }
    
    var color: String {
        switch self {
        case .unpaid: return "F59E0B"
        case .paid: return "10B981"
        case .partial: return "3B82F6"
        case .overdue: return "EF4444"
        case .waived: return "6B7280"
        }
    }
}

enum PaymentMode: String, Codable, CaseIterable {
    case cash
    case card
    case insurance
    case upi
    case bankTransfer = "bank_transfer"
    
    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .card: return "Card"
        case .insurance: return "Insurance"
        case .upi: return "UPI"
        case .bankTransfer: return "Bank Transfer"
        }
    }
}
