//
//  PricingConfig.swift
//  MedNex
//
//  Central pricing lookup for appointment fees and lab test costs.
//

import Foundation

enum PricingConfig {
    
    // MARK: - Appointment Pricing (₹)
    
    static func price(for type: AppointmentType) -> Int {
        switch type {
        case .consultation: return 500
        case .followUp:     return 300
        case .emergency:    return 1500
        case .checkup:      return 400
        case .procedure:    return 2000
        }
    }
    
    // MARK: - Lab Test Pricing by Category (₹)
    
    static func price(for category: LabTestCategory) -> Int {
        switch category {
        case .bloodWork:      return 800
        case .urinalysis:     return 500
        case .imaging:        return 2500
        case .biopsy:         return 3500
        case .cardiology:     return 2000
        case .microbiology:   return 1200
        case .hormonal:       return 1500
        case .genetic:        return 5000
        case .other:          return 600
        }
    }
    
    /// Total cost for multiple lab tests in a single category
    static func totalLabPrice(testCount: Int, category: LabTestCategory) -> Int {
        price(for: category) * testCount
    }
    
    // MARK: - Formatting
    
    static func formatted(_ amount: Int) -> String {
        "₹\(amount.formatted())"
    }
}
