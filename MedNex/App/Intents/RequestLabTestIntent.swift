//
//  RequestLabTestIntent.swift
//  MedNex
//
//  Siri App Intent: "Request a lab test in MedNex"
//  Lets patients request lab tests via voice command.

import AppIntents
import SwiftUI

struct RequestLabTestIntent: AppIntent {
    static var title: LocalizedStringResource = "Request Lab Test"
    static var description: IntentDescription = "Request a lab test by specifying the test type."
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Test Type")
    var testType: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Request a \(\.$testType) lab test")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let test = testType ?? "Complete Blood Count"
        
        // Simulated slot assignment
        let slotDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let slotFormatter = DateFormatter()
        slotFormatter.dateStyle = .medium
        slotFormatter.timeStyle = .short
        
        return .result(
            dialog: "Your \(test) lab test has been requested. Your estimated slot is \(slotFormatter.string(from: slotDate)). Please visit the lab 15 minutes before."
        ) {
            LabTestRequestSnippetView(testName: test, slotDate: slotDate)
        }
    }
}

struct LabTestRequestSnippetView: View {
    let testName: String
    let slotDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flask.fill")
                    .foregroundStyle(.orange)
                Text("Lab Test Requested")
                    .font(.headline)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(testName)
                        .font(.subheadline.weight(.semibold))
                    Text("Walk-in — no doctor referral needed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(slotDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline.weight(.medium))
                    Text(slotDate.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 4) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text("Arrive 15 minutes before your slot")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
