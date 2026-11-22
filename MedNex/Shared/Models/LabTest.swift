//
//  LabTest.swift
//  MedNex
//

import Foundation

struct LabTest: Codable, Identifiable, Hashable {
    var id: String
    var patientId: String
    var patientName: String
    var doctorId: String
    var doctorName: String
    var testName: String
    var testCategory: LabTestCategory
    var status: LabTestStatus
    var priority: LabTestPriority
    var results: [LabTestResult]
    var notes: String
    var reportPDFURL: String?
    var orderedAt: Date
    var completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, status, priority, results, notes
        case patientId = "patient_id"
        case patientName = "patient_name"
        case doctorId = "doctor_id"
        case doctorName = "doctor_name"
        case testName = "test_name"
        case testCategory = "test_category"
        case reportPDFURL = "report_pdf_url"
        case orderedAt = "ordered_at"
        case completedAt = "completed_at"
    }
    
    init(
        id: String = UUID().uuidString,
        patientId: String,
        patientName: String = "",
        doctorId: String,
        doctorName: String = "",
        testName: String,
        testCategory: LabTestCategory = .bloodWork,
        status: LabTestStatus = .pending,
        priority: LabTestPriority = .routine,
        results: [LabTestResult] = [],
        notes: String = "",
        reportPDFURL: String? = nil,
        orderedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.patientName = patientName
        self.doctorId = doctorId
        self.doctorName = doctorName
        self.testName = testName
        self.testCategory = testCategory
        self.status = status
        self.priority = priority
        self.results = results
        self.notes = notes
        self.reportPDFURL = reportPDFURL
        self.orderedAt = orderedAt
        self.completedAt = completedAt
    }
}

struct LabTestResult: Codable, Identifiable, Hashable {
    var id: String
    var parameterName: String
    var value: String
    var unit: String
    var normalRange: String
    var isAbnormal: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, value, unit
        case parameterName = "parameter_name"
        case normalRange = "normal_range"
        case isAbnormal = "is_abnormal"
    }
    
    init(
        id: String = UUID().uuidString,
        parameterName: String = "",
        value: String = "",
        unit: String = "",
        normalRange: String = "",
        isAbnormal: Bool = false
    ) {
        self.id = id
        self.parameterName = parameterName
        self.value = value
        self.unit = unit
        self.normalRange = normalRange
        self.isAbnormal = isAbnormal
    }
}

enum LabTestStatus: String, Codable, CaseIterable {
    case pending
    case received
    case processing
    case completed
    case cancelled
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .received: return "tray.and.arrow.down.fill"
        case .processing: return "gearshape.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

enum LabTestCategory: String, Codable, CaseIterable {
    case bloodWork = "Blood Work"
    case urinalysis = "Urinalysis"
    case imaging = "Imaging"
    case biopsy = "Biopsy"
    case cardiology = "Cardiology"
    case microbiology = "Microbiology"
    case hormonal = "Hormonal"
    case genetic = "Genetic"
    case other = "Other"
}

enum LabTestPriority: String, Codable, CaseIterable {
    case routine
    case urgent
    case stat
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .routine: return "3B82F6"
        case .urgent: return "F59E0B"
        case .stat: return "EF4444"
        }
    }
}
