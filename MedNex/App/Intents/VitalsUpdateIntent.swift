//
//  VitalsUpdateIntent.swift
//  MedNex
//
//  Siri App Intent: "Log vitals for a patient in MedNex"
//  Nurse-focused intent for quick vitals logging via voice.

import AppIntents
import SwiftUI

struct VitalsUpdateIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Patient Vitals"
    static var description: IntentDescription = "Quickly log patient vitals including heart rate and blood pressure via voice."
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Patient Name")
    var patientName: String?
    
    @Parameter(title: "Heart Rate")
    var heartRate: Int?
    
    @Parameter(title: "Blood Pressure (Systolic)")
    var systolic: Int?
    
    @Parameter(title: "Blood Pressure (Diastolic)")
    var diastolic: Int?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log vitals for \(\.$patientName): HR \(\.$heartRate), BP \(\.$systolic)/\(\.$diastolic)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let patient = patientName ?? "Unknown Patient"
        let hr = heartRate ?? 0
        let sys = systolic ?? 0
        let dia = diastolic ?? 0
        
        var warnings: [String] = []
        if hr > 0 && (hr < 60 || hr > 100) { warnings.append("Heart rate abnormal (\(hr) bpm)") }
        if sys > 0 && (sys < 90 || sys > 140) { warnings.append("Systolic BP abnormal (\(sys) mmHg)") }
        if dia > 0 && (dia < 60 || dia > 90) { warnings.append("Diastolic BP abnormal (\(dia) mmHg)") }
        
        let hasWarning = !warnings.isEmpty
        let warningText = hasWarning ? " ⚠️ Abnormal values detected — doctor notified." : ""
        
        var dialog = "Vitals logged for \(patient)."
        if hr > 0 { dialog += " Heart rate: \(hr) bpm." }
        if sys > 0 && dia > 0 { dialog += " Blood pressure: \(sys)/\(dia)." }
        dialog += warningText
        
        return .result(
            dialog: "\(dialog)"
        ) {
            VitalsUpdateSnippetView(
                patientName: patient,
                heartRate: hr,
                systolic: sys,
                diastolic: dia,
                warnings: warnings
            )
        }
    }
}

struct VitalsUpdateSnippetView: View {
    let patientName: String
    let heartRate: Int
    let systolic: Int
    let diastolic: Int
    let warnings: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(.red)
                Text("Vitals Logged")
                    .font(.headline)
            }
            
            Divider()
            
            Text(patientName)
                .font(.subheadline.weight(.semibold))
            
            HStack(spacing: 16) {
                if heartRate > 0 {
                    VStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("\(heartRate)")
                            .font(.subheadline.weight(.bold))
                        Text("bpm")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if systolic > 0 && diastolic > 0 {
                    VStack(spacing: 2) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("\(systolic)/\(diastolic)")
                            .font(.subheadline.weight(.bold))
                        Text("mmHg")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if !warnings.isEmpty {
                Divider()
                ForEach(warnings, id: \.self) { warning in
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text(warning)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.caption)
                    Text("Doctor has been notified")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("All values within normal range")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
