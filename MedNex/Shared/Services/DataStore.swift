//
//  DataStore.swift
//  MedNex
//
//  Central mutable data store for the entire app.
//  Uses write-through cache: UI updates instantly (in-memory),
//  Supabase writes fire in background for persistence.
//  Falls back to MockDataService when Supabase is unavailable.

import Foundation
import Observation

@Observable
final class DataStore: @unchecked Sendable {
    
    /// Shared singleton — used by App Intents (Siri Shortcuts) to access live data.
    /// The same instance is also injected into SwiftUI via `.environment()`.
    static let shared = DataStore()
    
    // MARK: - Core Data
    
    var appointments: [Appointment]
    var prescriptions: [Prescription]
    var labTests: [LabTest]
    var vitalRecords: [VitalRecord]
    var bills: [Bill]
    var notifications: [MedNexNotification]
    
    // MARK: - Staff / Resources
    
    var staff: [Staff]
    var doctors: [Doctor]
    var departments: [Department]
    var inventory: [InventoryItem]
    var beds: [Bed]
    
    // MARK: - Patient
    
    var patient: Patient
    
    // MARK: - Drug Database
    
    let drugDatabase: [Medicine] = MockDataService.drugDatabase
    
    // MARK: - Loading State
    
    var isLoadingFromBackend = false
    var backendError: String?
    
    private let log = LoggingService.shared
    
    // MARK: - Init (starts with mock data, replaced after login)
    
    init() {
        self.appointments = MockDataService.sampleAppointments
        self.prescriptions = MockDataService.samplePrescriptions
        self.labTests = MockDataService.sampleLabTests
        self.vitalRecords = MockDataService.sampleVitalRecords()
        self.bills = MockDataService.sampleBills
        self.notifications = MockDataService.sampleNotifications
        self.staff = MockDataService.sampleStaff
        self.doctors = MockDataService.sampleDoctors
        self.departments = MockDataService.sampleDepartments
        self.inventory = MockDataService.sampleInventory
        self.patient = MockDataService.samplePatient
        self.beds = Self.generateSampleBeds()
    }
    
    // MARK: - Load from Supabase
    
    /// Clears all in-memory data to empty arrays. Called before loading from Supabase
    /// to prevent stale mock data from persisting.
    @MainActor
    func clearData() {
        appointments = []
        prescriptions = []
        labTests = []
        vitalRecords = []
        bills = []
        notifications = []
        staff = []
        doctors = []
        departments = []
        inventory = []
        beds = []
    }
    
    /// Call after successful login to load the user's real data from Supabase.
    /// Clears stale data first, then fetches fresh data. Falls back to mock data on error.
    func loadFromSupabase(userId: String, role: UserRole) async {
        #if canImport(Supabase)
        // Clear stale data so re-login always starts fresh
        await MainActor.run {
            clearData()
            isLoadingFromBackend = true
            // Sync patient ID with Firebase UID so bookings use the correct ID
            patient.id = userId
            patient.userId = userId
        }
        log.data("📡 Loading data from Supabase for user: \(userId), role: \(role.rawValue)")
        
        do {
            switch role {
            case .patient:
                try await loadPatientData(userId: userId)
            case .doctor:
                try await loadDoctorData(userId: userId)
            case .admin:
                try await loadAdminData()
            case .nurse:
                try await loadNurseData(userId: userId)
            case .labTechnician:
                try await loadLabTechData()
            case .pharmacist:
                try await loadPharmacistData()
            case .receptionist:
                try await loadAdminData()
            case .accountant:
                try await loadAdminData()
            }
            
            log.data("✅ Supabase data loaded successfully")
            await MainActor.run { backendError = nil }
        } catch {
            log.warning("⚠️ Supabase load failed, falling back to mock data: \(error.localizedDescription)")
            print("⚠️ Supabase load error: \(error)")
            // Fall back to mock data so the app isn't completely empty
            await MainActor.run {
                self.appointments = MockDataService.sampleAppointments
                self.prescriptions = MockDataService.samplePrescriptions
                self.labTests = MockDataService.sampleLabTests
                self.vitalRecords = MockDataService.sampleVitalRecords()
                self.bills = MockDataService.sampleBills
                self.notifications = MockDataService.sampleNotifications
                self.staff = MockDataService.sampleStaff
                self.doctors = MockDataService.sampleDoctors
                self.departments = MockDataService.sampleDepartments
                self.inventory = MockDataService.sampleInventory
                backendError = error.localizedDescription
            }
        }
        
        await MainActor.run { isLoadingFromBackend = false }
        #endif
    }
    
    #if canImport(Supabase)
    private func loadPatientData(userId: String) async throws {
        let repo = PatientRepository.shared
        
        // Helper: fetch or return empty on failure (one table error shouldn't kill the rest)
        func safeFetch<T>(_ label: String, _ block: () async throws -> [T]) async -> [T] {
            do { return try await block() }
            catch { print("⚠️ Failed to load \(label): \(error)"); return [] }
        }
        
        let appts = await safeFetch("appointments") { try await repo.fetchAppointments(patientId: userId) }
        let rxs = await safeFetch("prescriptions") { try await repo.fetchPrescriptions(patientId: userId) }
        let labs = await safeFetch("lab tests") { try await repo.fetchLabTests(patientId: userId) }
        let vitals = await safeFetch("vitals") { try await repo.fetchVitalRecords(patientId: userId) }
        let fetchedBills = await safeFetch("bills") { try await repo.fetchBills(patientId: userId) }
        let notifs = await safeFetch("notifications") { try await repo.fetchNotifications(userId: userId) }
        let docs = await safeFetch("doctors") { try await repo.fetchAvailableDoctors() }
        
        await MainActor.run {
            self.appointments = appts
            self.prescriptions = rxs
            self.labTests = labs
            self.vitalRecords = vitals
            self.bills = fetchedBills
            self.notifications = notifs
            self.doctors = docs
        }
        print("📊 Patient data loaded — Appointments: \(appts.count), Prescriptions: \(rxs.count), Labs: \(labs.count), Doctors: \(docs.count)")
    }
    
    private func loadDoctorData(userId: String) async throws {
        let repo = DoctorRepository.shared
        
        async let fetchedAppointments = repo.fetchAppointments(doctorId: userId)
        async let fetchedPrescriptions = repo.fetchPrescriptions(doctorId: userId)
        async let fetchedLabOrders = repo.fetchLabOrders(doctorId: userId)
        
        let (appts, rxs, labs) = try await (fetchedAppointments, fetchedPrescriptions, fetchedLabOrders)
        
        await MainActor.run {
            self.appointments = appts
            self.prescriptions = rxs
            self.labTests = labs
        }
        print("📊 Doctor data loaded — Appointments: \(appts.count), Prescriptions: \(rxs.count), Labs: \(labs.count)")
    }
    
    private func loadAdminData() async throws {
        let repo = AdminRepository.shared
        
        async let fetchedStaff = repo.fetchAllStaff()
        async let fetchedDepartments = repo.fetchDepartments()
        async let fetchedInventory = repo.fetchInventory()
        async let fetchedBeds = repo.fetchBeds()
        
        let (s, d, inv, bedInfos) = try await (fetchedStaff, fetchedDepartments, fetchedInventory, fetchedBeds)
        
        // Convert BedInfo (Supabase DTO) → Bed (app model)
        let convertedBeds = bedInfos.map { info in
            Bed(
                id: info.id,
                number: info.number,
                ward: info.ward,
                floor: info.floor,
                status: BedStatus(rawValue: info.status) ?? .available,
                patientName: info.patient_name
            )
        }
        
        await MainActor.run {
            self.staff = s
            self.departments = d
            self.inventory = inv
            self.beds = convertedBeds
        }
    }
    
    private func loadNurseData(userId: String) async throws {
        // Nurses see appointments and vitals
        let patientRepo = PatientRepository.shared
        let notifs = try await patientRepo.fetchNotifications(userId: userId)
        
        await MainActor.run {
            self.notifications = notifs
        }
    }
    
    private func loadLabTechData() async throws {
        // Lab techs primarily see lab tests
        let supabase = SupabaseService.shared
        let labs: [LabTest] = try await supabase.fetch(from: "lab_tests")
        
        await MainActor.run {
            self.labTests = labs + MockDataService.sampleLabTests
        }
    }
    
    private func loadPharmacistData() async throws {
        // Pharmacists see prescriptions and inventory
        let supabase = SupabaseService.shared
        let rxs: [Prescription] = try await supabase.fetch(from: "prescriptions")
        let inv: [InventoryItem] = try await supabase.fetch(from: "inventory_items")
        
        await MainActor.run {
            self.prescriptions = rxs
            self.inventory = inv
        }
    }
    #endif
    
    // MARK: - Supabase Background Write Helper
    
    private func syncToSupabase(_ operation: @escaping @Sendable () async throws -> Void) {
        #if canImport(Supabase)
        Task.detached(priority: .utility) { [log] in
            do {
                try await operation()
                log.data("✅ Supabase sync succeeded")
            } catch {
                log.warning("⚠️ Supabase sync failed: \(error.localizedDescription)")
                print("")
                print("🔴🔴🔴 SUPABASE SYNC ERROR 🔴🔴🔴")
                print("Error: \(error)")
                print("Description: \(error.localizedDescription)")
                print("🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴")
                print("")
            }
        }
        #endif
    }
    
    // MARK: - Appointments
    
    func bookAppointment(
        patientId: String,
        patientName: String,
        doctorId: String,
        doctorName: String,
        specialty: MedicalSpecialty,
        dateTime: Date,
        type: AppointmentType,
        notes: String
    ) -> Appointment {
        let appointment = Appointment(
            id: UUID().uuidString,
            patientId: patientId,
            patientName: patientName,
            doctorId: doctorId,
            doctorName: doctorName,
            specialty: specialty,
            dateTime: dateTime,
            type: type,
            notes: notes
        )
        appointments.insert(appointment, at: 0)
        
        addNotification(
            title: "Appointment Booked",
            message: "Your appointment with \(doctorName) on \(dateTime.shortDate) has been confirmed.",
            type: .appointmentBooked
        )
        
        // Sync to Supabase
        let appt = appointment
        syncToSupabase {
            try await PatientRepository.shared.bookAppointment(appt)
        }
        
        return appointment
    }
    
    func cancelAppointment(_ id: String) {
        if let index = appointments.firstIndex(where: { $0.id == id }) {
            appointments[index].status = .cancelled
            addNotification(
                title: "Appointment Cancelled",
                message: "Your appointment with \(appointments[index].doctorName) has been cancelled.",
                type: .appointmentCancelled
            )
            
            syncToSupabase {
                try await PatientRepository.shared.cancelAppointment(id: id, reason: "Cancelled by user")
            }
        }
    }
    
    func rescheduleAppointment(_ id: String, to newDate: Date) {
        if let index = appointments.firstIndex(where: { $0.id == id }) {
            appointments[index].dateTime = newDate
            addNotification(
                title: "Appointment Rescheduled",
                message: "Your appointment has been rescheduled to \(newDate.shortDate).",
                type: .appointmentReminder
            )
            
            let updated = appointments[index]
            syncToSupabase {
                try await SupabaseService.shared.update(updated, in: "appointments", id: id)
            }
        }
    }
    
    func completeAppointment(_ id: String) {
        if let index = appointments.firstIndex(where: { $0.id == id }) {
            appointments[index].status = .completed
            
            syncToSupabase {
                try await DoctorRepository.shared.updateAppointmentStatus(id: id, status: .completed)
            }
        }
    }
    
    func startAppointment(_ id: String) {
        if let index = appointments.firstIndex(where: { $0.id == id }) {
            appointments[index].status = .inProgress
            
            syncToSupabase {
                try await DoctorRepository.shared.updateAppointmentStatus(id: id, status: .inProgress)
            }
        }
    }
    
    /// Convenience overload used by AppointmentBookingView (uses default patient)
    @discardableResult
    func bookAppointment(
        doctor: Doctor,
        date: Date,
        time: String,
        type: AppointmentType
    ) -> Appointment {
        return bookAppointment(
            patientId: patient.id,
            patientName: patient.personalInfo.fullName,
            doctorId: doctor.userId.isEmpty ? doctor.id : doctor.userId,
            doctorName: doctor.name,
            specialty: doctor.specialty,
            dateTime: date,
            type: type,
            notes: ""
        )
    }
    
    // MARK: - Prescriptions
    
    func createPrescription(
        appointmentId: String,
        patientId: String,
        patientName: String,
        doctorId: String,
        doctorName: String,
        medicines: [PrescribedMedicine],
        diagnosis: String,
        notes: String = ""
    ) -> Prescription {
        let prescription = Prescription(
            id: UUID().uuidString,
            appointmentId: appointmentId,
            patientId: patientId,
            patientName: patientName,
            doctorId: doctorId,
            doctorName: doctorName,
            medicines: medicines,
            diagnosis: diagnosis,
            notes: notes,
            createdAt: Date()
        )
        prescriptions.insert(prescription, at: 0)
        
        addNotification(
            title: "New Prescription",
            message: "Dr. \(doctorName) has prescribed medication for \(diagnosis).",
            type: .prescriptionReady
        )
        
        let rx = prescription
        syncToSupabase {
            try await DoctorRepository.shared.createPrescription(rx)
        }
        
        return prescription
    }
    
    func updatePrescriptionStatus(id: String, status: PrescriptionStatus) {
        if let index = prescriptions.firstIndex(where: { $0.id == id }) {
            prescriptions[index].status = status
            
            let updated = prescriptions[index]
            syncToSupabase {
                try await SupabaseService.shared.update(updated, in: "prescriptions", id: id)
            }
        }
    }
    
    // MARK: - Lab Tests
    
    func orderLabTest(
        patientId: String,
        patientName: String,
        doctorId: String,
        doctorName: String,
        testName: String,
        testCategory: LabTestCategory,
        priority: LabTestPriority = .routine,
        notes: String = ""
    ) -> LabTest {
        let labTest = LabTest(
            id: UUID().uuidString,
            patientId: patientId,
            patientName: patientName,
            doctorId: doctorId,
            doctorName: doctorName,
            testName: testName,
            testCategory: testCategory,
            status: .pending,
            priority: priority,
            notes: notes,
            orderedAt: Date()
        )
        labTests.insert(labTest, at: 0)
        
        addNotification(
            title: "Lab Test Ordered",
            message: "\(testName) has been ordered by Dr. \(doctorName).",
            type: .labResultReady
        )
        
        let test = labTest
        syncToSupabase {
            try await DoctorRepository.shared.createLabOrder(test)
        }
        
        return labTest
    }
    
    func updateLabTestStatus(_ id: String, status: LabTestStatus, results: [LabTestResult]? = nil) {
        if let index = labTests.firstIndex(where: { $0.id == id }) {
            labTests[index].status = status
            if let results = results {
                labTests[index].results = results
                labTests[index].completedAt = Date()
            }
            
            let updated = labTests[index]
            syncToSupabase {
                try await SupabaseService.shared.update(updated, in: "lab_tests", id: id)
            }
        }
    }
    
    // MARK: - Notifications
    
    func addNotification(title: String, message: String, type: NotificationType) {
        let notification = MedNexNotification(
            id: UUID().uuidString,
            userId: patient.userId,
            type: type,
            title: title,
            body: message,
            isRead: false,
            createdAt: Date()
        )
        notifications.insert(notification, at: 0)
        
        let notif = notification
        syncToSupabase {
            try await SupabaseService.shared.insert(notif, into: "notifications")
        }
    }
    
    func markNotificationRead(_ id: String) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
            
            syncToSupabase {
                try await PatientRepository.shared.markNotificationRead(id: id)
            }
        }
    }
    
    func markAllNotificationsRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
        
        // Sync each in background
        let ids = notifications.map(\.id)
        syncToSupabase {
            for id in ids {
                try await PatientRepository.shared.markNotificationRead(id: id)
            }
        }
    }
    
    // MARK: - Staff Management
    
    func addStaff(_ member: Staff) {
        staff.append(member)
        
        let s = member
        syncToSupabase {
            try await AdminRepository.shared.createStaff(s)
        }
    }
    
    func removeStaff(_ id: String) {
        staff.removeAll { $0.id == id }
        
        syncToSupabase {
            try await AdminRepository.shared.deleteStaff(id: id)
        }
    }
    
    func updateStaff(_ updated: Staff) {
        if let index = staff.firstIndex(where: { $0.id == updated.id }) {
            staff[index] = updated
            
            let s = updated
            syncToSupabase {
                try await AdminRepository.shared.updateStaff(s)
            }
        }
    }
    
    // MARK: - Inventory
    
    func updateInventoryStock(_ id: String, newStock: Int) {
        if let index = inventory.firstIndex(where: { $0.id == id }) {
            inventory[index].stock = newStock
            
            let updated = inventory[index]
            syncToSupabase {
                try await AdminRepository.shared.updateInventoryItem(updated)
            }
        }
    }
    
    func addInventoryItem(_ item: InventoryItem) {
        inventory.append(item)
        
        let i = item
        syncToSupabase {
            try await SupabaseService.shared.insert(i, into: "inventory_items")
        }
    }
    
    func removeInventoryItem(_ id: String) {
        inventory.removeAll { $0.id == id }
        
        syncToSupabase {
            try await SupabaseService.shared.delete(from: "inventory_items", id: id)
        }
    }
    
    // MARK: - Bed Management
    
    func updateBedStatus(_ id: String, status: BedStatus, patientName: String? = nil) {
        if let index = beds.firstIndex(where: { $0.id == id }) {
            beds[index].status = status
            beds[index].patientName = patientName
            
            let statusStr = status.rawValue.lowercased()
            syncToSupabase {
                try await AdminRepository.shared.updateBedStatus(bedId: id, status: statusStr, patientName: patientName)
            }
        }
    }
    
    // MARK: - Bills
    
    func createBill(
        appointmentId: String,
        patientId: String,
        patientName: String,
        items: [BillItem],
        tax: Double,
        discount: Double
    ) -> Bill {
        let subtotal = items.reduce(0) { $0 + $1.total }
        let totalAmount = subtotal + tax - discount
        
        let bill = Bill(
            id: UUID().uuidString,
            appointmentId: appointmentId,
            patientId: patientId,
            patientName: patientName,
            items: items,
            totalAmount: totalAmount,
            paidAmount: 0,
            status: .unpaid,
            createdAt: Date()
        )
        bills.insert(bill, at: 0)
        
        let b = bill
        syncToSupabase {
            try await SupabaseService.shared.insert(b, into: "bills")
        }
        
        return bill
    }
    
    func markBillPaid(_ id: String, mode: PaymentMode) {
        if let index = bills.firstIndex(where: { $0.id == id }) {
            bills[index].paidAmount = bills[index].totalAmount
            bills[index].paymentMode = mode
            bills[index].status = .paid
            bills[index].paidAt = Date()
            
            let updated = bills[index]
            syncToSupabase {
                try await SupabaseService.shared.update(updated, in: "bills", id: id)
            }
        }
    }
    
    // MARK: - Vitals
    
    func addVitalRecord(_ record: VitalRecord) {
        vitalRecords.insert(record, at: 0)
        
        let r = record
        syncToSupabase {
            try await DoctorRepository.shared.addVitalRecord(r)
        }
    }
    
    // MARK: - Departments
    
    func addDepartment(_ dept: Department) {
        departments.append(dept)
        
        let d = dept
        syncToSupabase {
            try await AdminRepository.shared.createDepartment(d)
        }
    }
    
    func removeDepartment(_ id: String) {
        departments.removeAll { $0.id == id }
        
        syncToSupabase {
            try await SupabaseService.shared.delete(from: "departments", id: id)
        }
    }
    
    // MARK: - Computed Helpers
    
    var upcomingAppointments: [Appointment] {
        appointments.filter { $0.status == .scheduled }.sorted { $0.dateTime < $1.dateTime }
    }
    
    var todayAppointments: [Appointment] {
        appointments.filter { Calendar.current.isDateInToday($0.dateTime) }
    }
    
    var pendingLabTests: [LabTest] {
        labTests.filter { $0.status == .pending || $0.status == .processing }
    }
    
    var completedLabTests: [LabTest] {
        labTests.filter { $0.status == .completed }
    }
    
    var lowStockItems: [InventoryItem] {
        inventory.filter { $0.stock <= $0.reorderLevel }
    }
    
    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    var totalRevenue: Double {
        bills.filter { $0.status == .paid }.reduce(0) { $0 + $1.paidAmount }
    }
    
    var availableBeds: Int {
        beds.filter { $0.status == .available }.count
    }
    
    var occupiedBeds: Int {
        beds.filter { $0.status == .occupied }.count
    }
    
    // MARK: - Sample Beds Generator
    
    private static func generateSampleBeds() -> [Bed] {
        let wardConfigs: [(name: String, count: Int, floor: String)] = [
            ("General Ward A", 12, "1st Floor"),
            ("General Ward B", 12, "1st Floor"),
            ("ICU", 8, "Ground Floor"),
            ("Pediatric", 10, "2nd Floor"),
            ("Maternity", 6, "2nd Floor"),
            ("Surgical", 10, "3rd Floor")
        ]
        let patientNames = ["Rahul S.", "Priya M.", "Amit K.", "Neha T.", "Suresh P."]
        var beds: [Bed] = []
        for config in wardConfigs {
            for i in 1...config.count {
                let status: BedStatus
                switch i % 5 {
                case 0: status = .maintenance
                case 1, 2: status = .occupied
                case 3: status = .cleaning
                default: status = .available
                }
                beds.append(Bed(
                    id: "\(config.name)-\(i)",
                    number: "\(config.name.prefix(3).uppercased())-\(String(format: "%02d", i))",
                    ward: config.name,
                    floor: config.floor,
                    status: status,
                    patientName: status == .occupied ? patientNames[i % patientNames.count] : nil
                ))
            }
        }
        return beds
    }
}

// MARK: - Bed Model

struct Bed: Identifiable {
    let id: String
    let number: String
    let ward: String
    let floor: String
    var status: BedStatus
    var patientName: String?
    
    var bedNumber: String { number }
}

enum BedStatus: String, CaseIterable {
    case available = "Available"
    case occupied = "Occupied"
    case maintenance = "Maintenance"
    case reserved = "Reserved"
    case cleaning = "Cleaning"
    
    var color: String {
        switch self {
        case .available: return "22C55E"
        case .occupied: return "EF4444"
        case .maintenance: return "F59E0B"
        case .reserved: return "6366F1"
        case .cleaning: return "8B5CF6"
        }
    }
    
    var icon: String {
        switch self {
        case .available: return "checkmark.circle.fill"
        case .occupied: return "person.fill"
        case .maintenance: return "wrench.fill"
        case .reserved: return "clock.fill"
        case .cleaning: return "sparkles"
        }
    }
}
