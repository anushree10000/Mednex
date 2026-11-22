//
//  VitalRecord.swift
//  MedNex
//

import Foundation

struct VitalRecord: Codable, Identifiable, Hashable {
    var id: String
    var patientId: String
    var recordedBy: String // staff who recorded
    var timestamp: Date
    var bloodPressureSystolic: Double?
    var bloodPressureDiastolic: Double?
    var heartRate: Double?
    var temperature: Double? // Fahrenheit
    var respiratoryRate: Double?
    var oxygenSaturation: Double? // SpO2 %
    var weight: Double? // kg
    var height: Double? // cm
    var bloodGlucose: Double?
    var notes: String
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, temperature, weight, height, notes
        case patientId = "patient_id"
        case recordedBy = "recorded_by"
        case bloodPressureSystolic = "blood_pressure_systolic"
        case bloodPressureDiastolic = "blood_pressure_diastolic"
        case heartRate = "heart_rate"
        case respiratoryRate = "respiratory_rate"
        case oxygenSaturation = "oxygen_saturation"
        case bloodGlucose = "blood_glucose"
    }
    
    init(
        id: String = UUID().uuidString,
        patientId: String,
        recordedBy: String = "",
        timestamp: Date = Date(),
        bloodPressureSystolic: Double? = nil,
        bloodPressureDiastolic: Double? = nil,
        heartRate: Double? = nil,
        temperature: Double? = nil,
        respiratoryRate: Double? = nil,
        oxygenSaturation: Double? = nil,
        weight: Double? = nil,
        height: Double? = nil,
        bloodGlucose: Double? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.patientId = patientId
        self.recordedBy = recordedBy
        self.timestamp = timestamp
        self.bloodPressureSystolic = bloodPressureSystolic
        self.bloodPressureDiastolic = bloodPressureDiastolic
        self.heartRate = heartRate
        self.temperature = temperature
        self.respiratoryRate = respiratoryRate
        self.oxygenSaturation = oxygenSaturation
        self.weight = weight
        self.height = height
        self.bloodGlucose = bloodGlucose
        self.notes = notes
    }
    
    var bloodPressureFormatted: String? {
        guard let sys = bloodPressureSystolic, let dia = bloodPressureDiastolic else { return nil }
        return "\(Int(sys))/\(Int(dia)) mmHg"
    }
    
    var heartRateFormatted: String? {
        guard let hr = heartRate else { return nil }
        return "\(Int(hr)) bpm"
    }
    
    var temperatureFormatted: String? {
        guard let temp = temperature else { return nil }
        return String(format: "%.1f°F", temp)
    }
    
    var spO2Formatted: String? {
        guard let spo2 = oxygenSaturation else { return nil }
        return "\(Int(spo2))%"
    }
}
