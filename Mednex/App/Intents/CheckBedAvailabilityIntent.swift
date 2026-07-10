//
//  CheckBedAvailabilityIntent.swift
//  MedNex
//
//  Siri App Intent: "Check bed availability in MedNex"
//  Returns available bed count by ward for staff users.

import AppIntents
import SwiftUI

struct CheckBedAvailabilityIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Bed Availability"
    static var description: IntentDescription = "Check how many beds are available, optionally filtered by ward."
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Ward")
    var ward: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Check bed availability in \(\.$ward)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Simulated bed data matching BedManagementView
        let wardData: [(String, Int, Int)] = [
            ("General Ward", 12, 5),
            ("ICU", 8, 2),
            ("Pediatrics", 8, 3),
            ("Maternity", 6, 2),
            ("Private Rooms", 4, 1),
        ]
        
        if let wardName = ward, !wardName.isEmpty {
            let matched = wardData.first { $0.0.lowercased().contains(wardName.lowercased()) }
            if let w = matched {
                return .result(
                    dialog: "\(w.0) has \(w.2) beds available out of \(w.1) total."
                ) {
                    BedAvailabilitySnippetView(wardData: [w])
                }
            }
        }
        
        let totalBeds = wardData.reduce(0) { $0 + $1.1 }
        let totalAvailable = wardData.reduce(0) { $0 + $1.2 }
        
        return .result(
            dialog: "There are \(totalAvailable) beds available out of \(totalBeds) total across all wards."
        ) {
            BedAvailabilitySnippetView(wardData: wardData)
        }
    }
}

struct BedAvailabilitySnippetView: View {
    let wardData: [(String, Int, Int)] // (name, total, available)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundStyle(.blue)
                Text("Bed Availability")
                    .font(.headline)
            }
            
            Divider()
            
            ForEach(wardData, id: \.0) { ward in
                HStack {
                    Text(ward.0)
                        .font(.subheadline)
                    Spacer()
                    Text("\(ward.2)/\(ward.1)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ward.2 == 0 ? .red : ward.2 <= 2 ? .orange : .green)
                    Text("available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
