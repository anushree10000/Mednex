//
//  ActivePrescriptionsIntent.swift
//  MedNex
//
//  Siri App Intent: "Show my prescriptions"
//  Lets patients quickly check their active medications and dosages.

import AppIntents
import SwiftUI

struct ActivePrescriptionsIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Active Prescriptions"
    static var description: IntentDescription = "Shows your currently active prescriptions with medicine names and dosages."
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let prescriptions = await DataStore.shared.prescriptions
        
        let active = prescriptions.filter { $0.status == .active }
        
        if active.isEmpty {
            return .result(
                dialog: "You don't have any active prescriptions right now."
            ) {
                ActivePrescriptionsSnippetView(prescriptions: [])
            }
        }
        
        let totalMeds = active.flatMap { $0.medicines }.count
        let medNoun = totalMeds == 1 ? "medication" : "medications"
        
        return .result(
            dialog: "You have \(active.count) active prescription\(active.count == 1 ? "" : "s") with \(totalMeds) \(medNoun)."
        ) {
            ActivePrescriptionsSnippetView(prescriptions: active)
        }
    }
}

// MARK: - Siri Snippet View
struct ActivePrescriptionsSnippetView: View {
    let prescriptions: [Prescription]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundStyle(.orange)
                Text("Active Prescriptions")
                    .font(.headline)
            }
            
            if prescriptions.isEmpty {
                Text("No active prescriptions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                Divider()
                
                ForEach(prescriptions) { rx in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(rx.diagnosis)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("Dr. \(rx.doctorName.replacingOccurrences(of: "Dr. ", with: ""))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        ForEach(rx.medicines) { med in
                            HStack(spacing: 6) {
                                Image(systemName: "capsule.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Text(med.name)
                                    .font(.caption.weight(.medium))
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(med.dosage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(med.frequency.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}
