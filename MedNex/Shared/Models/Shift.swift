//
//  Shift.swift
//  MedNex
//

import Foundation

struct Shift: Codable, Identifiable, Hashable {
    var id: String
    var staffId: String
    var staffName: String
    var date: Date
    var startTime: Date
    var endTime: Date
    var department: String
    var shiftType: ShiftType
    var notes: String
    
    enum CodingKeys: String, CodingKey {
        case id, date, department, notes
        case staffId = "staff_id"
        case staffName = "staff_name"
        case startTime = "start_time"
        case endTime = "end_time"
        case shiftType = "shift_type"
    }
    
    init(
        id: String = UUID().uuidString,
        staffId: String,
        staffName: String = "",
        date: Date = Date(),
        startTime: Date = Date(),
        endTime: Date = Date(),
        department: String = "",
        shiftType: ShiftType = .morning,
        notes: String = ""
    ) {
        self.id = id
        self.staffId = staffId
        self.staffName = staffName
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.department = department
        self.shiftType = shiftType
        self.notes = notes
    }
}
