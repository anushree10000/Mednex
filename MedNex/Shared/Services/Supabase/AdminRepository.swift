#if canImport(Supabase)
//
//  AdminRepository.swift
//  MedNex
//
//  Data access layer for admin dashboard, staff management, inventory, and reports.

import Foundation
import Supabase
import PostgREST

final class AdminRepository: @unchecked Sendable {
    static let shared = AdminRepository()
    
    private let supabase = SupabaseService.shared
    private let log = LoggingService.shared
    
    private init() {}
    
    // MARK: - Dashboard Stats
    
    struct DashboardStats {
        var totalPatients: Int
        var totalDoctors: Int
        var totalStaff: Int
        var todayAppointments: Int
        var pendingBills: Int
        var totalRevenue: Double
        var occupiedBeds: Int
        var totalBeds: Int
    }
    
    func fetchDashboardStats() async throws -> DashboardStats {
        log.data("Fetching admin dashboard stats")
        
        async let patients = supabase.count(from: "patients")
        async let doctors = supabase.count(from: "doctors")
        async let staff = supabase.count(from: "staff")
        async let todayAppts = fetchTodayAppointmentCount()
        async let unpaidBills = supabase.count(from: "bills", filters: [("status", "unpaid")])
        async let revenue = fetchTotalRevenue()
        async let beds = fetchBedOccupancy()
        
        let (p, d, s, ta, ub, rev, bedStats) = try await (patients, doctors, staff, todayAppts, unpaidBills, revenue, beds)
        
        return DashboardStats(
            totalPatients: p,
            totalDoctors: d,
            totalStaff: s,
            todayAppointments: ta,
            pendingBills: ub,
            totalRevenue: rev,
            occupiedBeds: bedStats.occupied,
            totalBeds: bedStats.total
        )
    }
    
    private func fetchTodayAppointmentCount() async throws -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let formatter = ISO8601DateFormatter()
        
        let response = try await supabase.client
            .from("appointments")
            .select("*", head: true, count: .exact)
            .gte("date_time", value: formatter.string(from: startOfDay))
            .lt("date_time", value: formatter.string(from: endOfDay))
            .execute()
        
        return response.count ?? 0
    }
    
    private func fetchTotalRevenue() async throws -> Double {
        struct RevenueRow: Decodable {
            let paid_amount: Double
        }
        let rows: [RevenueRow] = try await supabase.client
            .from("bills")
            .select("paid_amount")
            .eq("status", value: "paid")
            .execute()
            .value
        return rows.reduce(0) { $0 + $1.paid_amount }
    }
    
    private func fetchBedOccupancy() async throws -> (occupied: Int, total: Int) {
        let total = try await supabase.count(from: "beds")
        let occupied = try await supabase.count(from: "beds", filters: [("status", "occupied")])
        return (occupied, total)
    }
    
    // MARK: - Staff Management
    
    func fetchAllStaff() async throws -> [Staff] {
        try await supabase.fetch(from: "staff")
    }
    
    func createStaff(_ staff: Staff) async throws {
        try await supabase.insert(staff, into: "staff")
    }
    
    func updateStaff(_ staff: Staff) async throws {
        try await supabase.update(staff, in: "staff", id: staff.id)
    }
    
    func deleteStaff(id: String) async throws {
        try await supabase.delete(from: "staff", id: id)
    }
    
    // MARK: - Department Management
    
    func fetchDepartments() async throws -> [Department] {
        try await supabase.fetch(from: "departments")
    }
    
    func createDepartment(_ dept: Department) async throws {
        try await supabase.insert(dept, into: "departments")
    }
    
    func updateDepartment(_ dept: Department) async throws {
        try await supabase.update(dept, in: "departments", id: dept.id)
    }
    
    // MARK: - Inventory
    
    func fetchInventory() async throws -> [InventoryItem] {
        let response: [InventoryItem] = try await supabase.client
            .from("inventory_items")
            .select()
            .order("name", ascending: true)
            .execute()
            .value
        return response
    }
    
    func fetchLowStockItems() async throws -> [InventoryItem] {
        log.data("Fetching low stock items")
        // Fetch all and filter client-side since Supabase doesn't natively support
        // comparing two columns (stock <= reorder_level) without an RPC
        let allItems: [InventoryItem] = try await supabase.fetch(from: "inventory_items")
        return allItems.filter { $0.isLowStock }
    }
    
    func updateInventoryItem(_ item: InventoryItem) async throws {
        try await supabase.update(item, in: "inventory_items", id: item.id)
    }
    
    // MARK: - Shift Management
    
    func fetchShifts(date: Date? = nil) async throws -> [Shift] {
        if let date {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            return try await supabase.fetch(
                from: "shifts",
                filters: [("date", formatter.string(from: date))]
            )
        }
        return try await supabase.fetch(from: "shifts")
    }
    
    func createShift(_ shift: Shift) async throws {
        try await supabase.insert(shift, into: "shifts")
    }
    
    // MARK: - Bed Management
    
    struct BedInfo: Decodable, Identifiable {
        let id: String
        let number: String
        let ward: String
        let floor: String
        let status: String
        let patient_name: String?
    }
    
    func fetchBeds() async throws -> [BedInfo] {
        try await supabase.fetch(from: "beds")
    }
    
    func updateBedStatus(bedId: String, status: String, patientName: String? = nil) async throws {
        struct BedUpdate: Encodable {
            let status: String
            let patient_name: String?
        }
        try await supabase.client
            .from("beds")
            .update(BedUpdate(status: status, patient_name: patientName))
            .eq("id", value: bedId)
            .execute()
    }
    
    // MARK: - Reports
    
    func fetchAppointmentsByDateRange(start: Date, end: Date) async throws -> [Appointment] {
        let formatter = ISO8601DateFormatter()
        let response: [Appointment] = try await supabase.client
            .from("appointments")
            .select()
            .gte("date_time", value: formatter.string(from: start))
            .lte("date_time", value: formatter.string(from: end))
            .order("date_time", ascending: true)
            .execute()
            .value
        return response
    }
    
    func fetchRevenueByDateRange(start: Date, end: Date) async throws -> [Bill] {
        let formatter = ISO8601DateFormatter()
        let response: [Bill] = try await supabase.client
            .from("bills")
            .select()
            .gte("created_at", value: formatter.string(from: start))
            .lte("created_at", value: formatter.string(from: end))
            .execute()
            .value
        return response
    }
    
    // MARK: - Nurse-Patient Assignments
    
    struct NurseAssignment: Codable, Identifiable {
        var id: String
        var staffId: String
        var patientId: String
        var assignedDate: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case staffId = "staff_id"
            case patientId = "patient_id"
            case assignedDate = "assigned_date"
        }
    }
    
    func fetchNurseAssignments(staffId: String) async throws -> [NurseAssignment] {
        try await supabase.fetch(
            from: "nurse_patient_assignments",
            filters: [("staff_id", staffId)]
        )
    }
    
    func createNurseAssignment(_ assignment: NurseAssignment) async throws {
        try await supabase.insert(assignment, into: "nurse_patient_assignments")
    }
}
#endif
