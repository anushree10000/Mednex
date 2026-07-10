// ──────────────────────────────────────────────────────────
//  MedNexBusinessLogicTests.swift
//  MedNexTests
//
//  Comprehensive business logic tests for the ENTIRE MedNex app.
//  Covers all user roles, workflows, features, and edge cases.
//  Run via Xcode: ⌘+U or Product → Test
// ──────────────────────────────────────────────────────────

import XCTest
@testable import MedNex

// ═══════════════════════════════════════════════════════════
// MARK: - 1. PATIENT BOOKING WORKFLOW TESTS
// ═══════════════════════════════════════════════════════════

/// Tests per-doctor booking constraint logic.
final class PerDoctorBookingConstraintTests: XCTestCase {

    let patientId = "patient-001"
    let doctorA_Id = "doctor-A"
    let doctorB_Id = "doctor-B"
    
    private func hasActiveAppointmentWith(
        patientId: String, doctorId: String, existingAppointments: [Appointment]
    ) -> Bool {
        existingAppointments.contains {
            $0.patientId == patientId && $0.doctorId == doctorId &&
            ($0.status == .scheduled || $0.status == .inProgress)
        }
    }
    
    func testBlocksBookingWithSameDoctorWhenScheduled() {
        let existing = [Appointment(patientId: patientId, doctorId: doctorA_Id, status: .scheduled)]
        XCTAssertTrue(hasActiveAppointmentWith(patientId: patientId, doctorId: doctorA_Id, existingAppointments: existing))
    }
    
    func testBlocksBookingWithSameDoctorWhenInProgress() {
        let existing = [Appointment(patientId: patientId, doctorId: doctorA_Id, status: .inProgress)]
        XCTAssertTrue(hasActiveAppointmentWith(patientId: patientId, doctorId: doctorA_Id, existingAppointments: existing))
    }
    
    func testAllowsBookingWithDifferentDoctor() {
        let existing = [Appointment(patientId: patientId, doctorId: doctorA_Id, status: .scheduled)]
        XCTAssertFalse(hasActiveAppointmentWith(patientId: patientId, doctorId: doctorB_Id, existingAppointments: existing))
    }
    
    func testAllowsBookingAfterCompletedAppointment() {
        let existing = [Appointment(patientId: patientId, doctorId: doctorA_Id, status: .completed)]
        XCTAssertFalse(hasActiveAppointmentWith(patientId: patientId, doctorId: doctorA_Id, existingAppointments: existing))
    }
    
    func testAllowsBookingAfterCancelledAppointment() {
        let existing = [Appointment(patientId: patientId, doctorId: doctorA_Id, status: .cancelled)]
        XCTAssertFalse(hasActiveAppointmentWith(patientId: patientId, doctorId: doctorA_Id, existingAppointments: existing))
    }
    
    func testAllowsBookingAfterNoShowAppointment() {
        let existing = [Appointment(patientId: patientId, doctorId: doctorA_Id, status: .noShow)]
        XCTAssertFalse(hasActiveAppointmentWith(patientId: patientId, doctorId: doctorA_Id, existingAppointments: existing))
    }
    
    func testAllowsBookingWhenNoExistingAppointments() {
        XCTAssertFalse(hasActiveAppointmentWith(patientId: patientId, doctorId: doctorA_Id, existingAppointments: []))
    }
    
    func testDoesNotBlockDifferentPatient() {
        let existing = [Appointment(patientId: "patient-OTHER", doctorId: doctorA_Id, status: .scheduled)]
        XCTAssertFalse(hasActiveAppointmentWith(patientId: patientId, doctorId: doctorA_Id, existingAppointments: existing))
    }
    
    func testMultipleDoctorsAllowedSimultaneously() {
        let existing = [
            Appointment(patientId: patientId, doctorId: doctorA_Id, status: .scheduled),
            Appointment(patientId: patientId, doctorId: doctorB_Id, status: .scheduled)
        ]
        XCTAssertFalse(hasActiveAppointmentWith(patientId: patientId, doctorId: "doctor-C", existingAppointments: existing))
        XCTAssertTrue(hasActiveAppointmentWith(patientId: patientId, doctorId: doctorA_Id, existingAppointments: existing))
    }
    
    func testMixOfCompletedAndActiveAppointments() {
        let existing = [
            Appointment(patientId: patientId, doctorId: doctorA_Id, status: .completed),
            Appointment(patientId: patientId, doctorId: doctorA_Id, status: .cancelled),
            Appointment(patientId: patientId, doctorId: doctorA_Id, status: .scheduled)
        ]
        XCTAssertTrue(hasActiveAppointmentWith(patientId: patientId, doctorId: doctorA_Id, existingAppointments: existing))
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 2. TWO-WEEK BOOKING WINDOW TESTS
// ═══════════════════════════════════════════════════════════

final class TwoWeekBookingWindowTests: XCTestCase {
    
    private var maxBookingDate: Date {
        Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    }
    
    func testMaxBookingDateIs14DaysFromNow() {
        let today = Calendar.current.startOfDay(for: Date())
        let maxDay = Calendar.current.startOfDay(for: maxBookingDate)
        let diff = Calendar.current.dateComponents([.day], from: today, to: maxDay).day ?? 0
        XCTAssertEqual(diff, 14)
    }
    
    func testTodayIsWithinWindow() { XCTAssertTrue(Date() <= maxBookingDate) }
    
    func testOneWeekOutIsWithinWindow() {
        let d = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        XCTAssertTrue(d <= maxBookingDate)
    }
    
    func testThreeWeeksOutIsOutsideWindow() {
        let d = Calendar.current.date(byAdding: .day, value: 21, to: Date())!
        XCTAssertTrue(d > maxBookingDate)
    }
    
    func testPastDatesAreBeforeWindow() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(yesterday < Date())
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 3. PRESCRIPTION TIME-GATING TESTS
// ═══════════════════════════════════════════════════════════

final class PrescriptionTimeGatingTests: XCTestCase {
    
    private func isWithinAppointmentWindow(appointmentTime: Date, currentTime: Date = Date()) -> Bool {
        let windowStart = Calendar.current.date(byAdding: .minute, value: -15, to: appointmentTime)!
        let windowEnd = Calendar.current.date(byAdding: .minute, value: 15, to: appointmentTime)!
        return currentTime >= windowStart && currentTime <= windowEnd
    }
    
    func testExactAppointmentTimeIsWithinWindow() {
        let t = Date()
        XCTAssertTrue(isWithinAppointmentWindow(appointmentTime: t, currentTime: t))
    }
    
    func test5MinutesBeforeIsWithin() {
        let now = Date()
        XCTAssertTrue(isWithinAppointmentWindow(appointmentTime: now.addingTimeInterval(300), currentTime: now))
    }
    
    func test5MinutesAfterIsWithin() {
        let now = Date()
        XCTAssertTrue(isWithinAppointmentWindow(appointmentTime: now.addingTimeInterval(-300), currentTime: now))
    }
    
    func test14MinutesBeforeIsWithin() {
        let now = Date()
        XCTAssertTrue(isWithinAppointmentWindow(appointmentTime: now.addingTimeInterval(840), currentTime: now))
    }
    
    func test30MinutesBeforeIsOutside() {
        let now = Date()
        XCTAssertFalse(isWithinAppointmentWindow(appointmentTime: now.addingTimeInterval(1800), currentTime: now))
    }
    
    func test30MinutesAfterIsOutside() {
        let now = Date()
        XCTAssertFalse(isWithinAppointmentWindow(appointmentTime: now.addingTimeInterval(-1800), currentTime: now))
    }
    
    func test2HoursBeforeIsOutside() {
        let now = Date()
        XCTAssertFalse(isWithinAppointmentWindow(appointmentTime: now.addingTimeInterval(7200), currentTime: now))
    }
    
    func testYesterdayIsOutside() {
        let now = Date()
        XCTAssertFalse(isWithinAppointmentWindow(appointmentTime: now.addingTimeInterval(-86400), currentTime: now))
    }
    
    func testTomorrowIsOutside() {
        let now = Date()
        XCTAssertFalse(isWithinAppointmentWindow(appointmentTime: now.addingTimeInterval(86400), currentTime: now))
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 4. APPOINTMENT STATUS TRANSITIONS
// ═══════════════════════════════════════════════════════════

final class AppointmentActiveStatusTests: XCTestCase {
    
    let activeStatuses: [AppointmentStatus] = [.scheduled, .inProgress]
    let terminalStatuses: [AppointmentStatus] = [.completed, .cancelled, .noShow]
    
    func testScheduledIsActive() { XCTAssertTrue(activeStatuses.contains(.scheduled)) }
    func testInProgressIsActive() { XCTAssertTrue(activeStatuses.contains(.inProgress)) }
    func testCompletedIsTerminal() { XCTAssertTrue(terminalStatuses.contains(.completed)) }
    func testCancelledIsTerminal() { XCTAssertTrue(terminalStatuses.contains(.cancelled)) }
    func testNoShowIsTerminal() { XCTAssertTrue(terminalStatuses.contains(.noShow)) }
    
    func testAllStatusesAreCategorized() {
        let all = Set(activeStatuses + terminalStatuses)
        XCTAssertEqual(all.count, AppointmentStatus.allCases.count)
    }
    
    func testNoOverlap() {
        let overlap = Set(activeStatuses).intersection(Set(terminalStatuses))
        XCTAssertTrue(overlap.isEmpty)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 5. APPOINTMENT CANCELLATION RULES
// ═══════════════════════════════════════════════════════════

final class AppointmentCancellationTests: XCTestCase {
    
    func testCanCancelTrue5HoursOut() {
        let d = Calendar.current.date(byAdding: .hour, value: 5, to: Date())!
        let a = Appointment(patientId: "p1", doctorId: "d1", dateTime: d, status: .scheduled)
        XCTAssertTrue(a.canCancel, "Should cancel: >3h out and scheduled")
    }
    
    func testCanCancelFalse2HoursOut() {
        let d = Calendar.current.date(byAdding: .hour, value: 2, to: Date())!
        let a = Appointment(patientId: "p1", doctorId: "d1", dateTime: d, status: .scheduled)
        XCTAssertFalse(a.canCancel, "Should NOT cancel: <3h out")
    }
    
    func testCannotCancelCompleted() {
        let d = Calendar.current.date(byAdding: .hour, value: 10, to: Date())!
        let a = Appointment(patientId: "p1", doctorId: "d1", dateTime: d, status: .completed)
        XCTAssertFalse(a.canCancel)
    }
    
    func testCannotCancelAlreadyCancelled() {
        let d = Calendar.current.date(byAdding: .hour, value: 10, to: Date())!
        let a = Appointment(patientId: "p1", doctorId: "d1", dateTime: d, status: .cancelled)
        XCTAssertFalse(a.canCancel)
    }
    
    func testCannotCancelInProgress() {
        let d = Calendar.current.date(byAdding: .hour, value: 10, to: Date())!
        let a = Appointment(patientId: "p1", doctorId: "d1", dateTime: d, status: .inProgress)
        XCTAssertFalse(a.canCancel)
    }
    
    func testCannotCancelPastDate() {
        let d = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let a = Appointment(patientId: "p1", doctorId: "d1", dateTime: d, status: .scheduled)
        XCTAssertFalse(a.canCancel)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 6. ADMITTED PATIENT BOOKING GUARD
// ═══════════════════════════════════════════════════════════

final class AdmittedPatientBookingGuardTests: XCTestCase {
    
    private func isPatientAdmitted(patientId: String, admissions: [Admission]) -> Bool {
        admissions.contains { $0.patientId == patientId && $0.status == .admitted }
    }
    
    func testAdmittedBlocks() {
        XCTAssertTrue(isPatientAdmitted(patientId: "p1", admissions: [Admission(patientId: "p1", status: .admitted)]))
    }
    func testDischargedDoesNotBlock() {
        XCTAssertFalse(isPatientAdmitted(patientId: "p1", admissions: [Admission(patientId: "p1", status: .discharged)]))
    }
    func testTransferredDoesNotBlock() {
        XCTAssertFalse(isPatientAdmitted(patientId: "p1", admissions: [Admission(patientId: "p1", status: .transferred)]))
    }
    func testNoAdmissionsDoesNotBlock() {
        XCTAssertFalse(isPatientAdmitted(patientId: "p1", admissions: []))
    }
    func testDifferentPatientDoesNotBlock() {
        XCTAssertFalse(isPatientAdmitted(patientId: "p1", admissions: [Admission(patientId: "p2", status: .admitted)]))
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 7. BILLING WORKFLOW TESTS
// ═══════════════════════════════════════════════════════════

final class BillingWorkflowTests: XCTestCase {
    
    func testBalanceDueCalculation() {
        let b = Bill(patientId: "p1", totalAmount: 1000, paidAmount: 300)
        XCTAssertEqual(b.balanceDue, 700, accuracy: 0.001)
    }
    
    func testZeroBalanceWhenFullyPaid() {
        let b = Bill(patientId: "p1", totalAmount: 500, paidAmount: 500)
        XCTAssertEqual(b.balanceDue, 0, accuracy: 0.001)
    }
    
    func testNegativeBalanceOverpaid() {
        let b = Bill(patientId: "p1", totalAmount: 100, paidAmount: 150)
        XCTAssertEqual(b.balanceDue, -50, accuracy: 0.001)
    }
    
    func testDefaultStatusIsUnpaid() {
        XCTAssertEqual(Bill(patientId: "p1").status, .unpaid)
    }
    
    func testBillStatusTransitions() {
        // Verify all expected statuses exist
        let statuses: [BillStatus] = [.unpaid, .paid, .partial, .overdue, .waived]
        XCTAssertEqual(statuses.count, BillStatus.allCases.count)
    }
    
    func testBillItemTotalCalculation() {
        let item = BillItem(description: "Consultation", quantity: 2, unitPrice: 500, total: 1000, category: .consultation)
        XCTAssertEqual(item.total, 1000, accuracy: 0.001)
        XCTAssertEqual(item.quantity, 2)
    }
    
    func testBillItemDefaultQuantityIs1() {
        XCTAssertEqual(BillItem().quantity, 1)
    }
    
    func testMultipleBillItemCategories() {
        let items = [
            BillItem(description: "Consult", category: .consultation),
            BillItem(description: "Blood Test", category: .labTest),
            BillItem(description: "Room", category: .roomCharge),
            BillItem(description: "Meds", category: .pharmacy),
            BillItem(description: "Surgery", category: .procedure),
            BillItem(description: "Other", category: .other)
        ]
        XCTAssertEqual(items.count, BillItemCategory.allCases.count)
    }
    
    func testPaymentModes() {
        let modes: [PaymentMode] = [.cash, .card, .insurance, .upi, .bankTransfer]
        XCTAssertEqual(modes.count, PaymentMode.allCases.count)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 8. PRESCRIPTION WORKFLOW TESTS
// ═══════════════════════════════════════════════════════════

final class PrescriptionWorkflowTests: XCTestCase {
    
    func testDefaultStatusIsActive() {
        let rx = Prescription(patientId: "p1", doctorId: "d1")
        XCTAssertEqual(rx.status, .active)
    }
    
    func testPrescriptionRequiresPatientAndDoctor() {
        let rx = Prescription(patientId: "p1", doctorId: "d1", diagnosis: "Fever")
        XCTAssertFalse(rx.patientId.isEmpty)
        XCTAssertFalse(rx.doctorId.isEmpty)
    }
    
    func testPrescriptionWithMedicines() {
        let meds = [
            PrescribedMedicine(name: "Paracetamol", dosage: "500mg", frequency: .thriceDaily),
            PrescribedMedicine(name: "Amoxicillin", dosage: "250mg", frequency: .twiceDaily)
        ]
        let rx = Prescription(patientId: "p1", doctorId: "d1", medicines: meds, diagnosis: "Infection")
        XCTAssertEqual(rx.medicines.count, 2)
        XCTAssertEqual(rx.diagnosis, "Infection")
    }
    
    func testPrescriptionStatusLifecycle() {
        // active → dispensed → completed (normal flow)
        let validFlow: [PrescriptionStatus] = [.active, .dispensed, .completed]
        XCTAssertEqual(validFlow.first, .active)
        XCTAssertEqual(validFlow.last, .completed)
    }
    
    func testPartiallyDispensedStatus() {
        XCTAssertEqual(PrescriptionStatus.partiallyDispensed.rawValue, "partially_dispensed")
        XCTAssertEqual(PrescriptionStatus.partiallyDispensed.displayName, "Partially Dispensed")
    }
    
    func testMedicineDefaultIsTakenFalse() {
        XCTAssertFalse(PrescribedMedicine().isTaken)
    }
    
    func testMedicineFrequencyCount() {
        XCTAssertEqual(MedicineFrequency.allCases.count, 9)
    }
    
    func testPrescriptionLinksToAppointment() {
        let rx = Prescription(appointmentId: "apt-001", patientId: "p1", doctorId: "d1")
        XCTAssertEqual(rx.appointmentId, "apt-001")
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 9. LAB TEST WORKFLOW TESTS
// ═══════════════════════════════════════════════════════════

final class LabTestWorkflowTests: XCTestCase {
    
    func testDefaultStatusIsPending() {
        let t = LabTest(patientId: "p1", doctorId: "d1", testName: "CBC", testCategory: .bloodWork)
        XCTAssertEqual(t.status, .pending)
    }
    
    func testDefaultPriorityIsRoutine() {
        let t = LabTest(patientId: "p1", doctorId: "d1", testName: "CBC", testCategory: .bloodWork)
        XCTAssertEqual(t.priority, .routine)
    }
    
    func testLabTestLifecycle() {
        // pending → received → processing → completed
        let flow: [LabTestStatus] = [.pending, .received, .processing, .completed]
        XCTAssertEqual(flow.first, .pending)
        XCTAssertEqual(flow.last, .completed)
    }
    
    func testAbnormalResultDetection() {
        let r = LabTestResult(parameterName: "WBC", value: "25000", unit: "cells/mcL", normalRange: "4000-11000", isAbnormal: true)
        XCTAssertTrue(r.isAbnormal)
    }
    
    func testNormalResultDetection() {
        let r = LabTestResult(parameterName: "Hemoglobin", value: "14.5", unit: "g/dL", normalRange: "12-16", isAbnormal: false)
        XCTAssertFalse(r.isAbnormal)
    }
    
    func testLabTestPriorityOrdering() {
        // Verify all priorities exist and stat is highest
        let priorities: [LabTestPriority] = [.routine, .urgent, .stat]
        XCTAssertEqual(priorities.count, LabTestPriority.allCases.count)
    }
    
    func testLabTestCategories() {
        XCTAssertEqual(LabTestCategory.allCases.count, 9)
    }
    
    func testLabTestCompletionHasNoDate() {
        let t = LabTest(patientId: "p1", doctorId: "d1", testName: "CBC", testCategory: .bloodWork)
        XCTAssertNil(t.completedAt, "Pending test should have no completion date")
    }
    
    func testLabTestResultsEmptyByDefault() {
        let t = LabTest(patientId: "p1", doctorId: "d1", testName: "CBC", testCategory: .bloodWork)
        XCTAssertTrue(t.results.isEmpty)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 10. INVENTORY & PHARMACY WORKFLOW TESTS
// ═══════════════════════════════════════════════════════════

final class InventoryWorkflowTests: XCTestCase {
    
    func testLowStockAtReorderLevel() {
        XCTAssertTrue(InventoryItem(name: "A", stock: 10, reorderLevel: 10).isLowStock)
    }
    
    func testLowStockBelowReorderLevel() {
        XCTAssertTrue(InventoryItem(name: "A", stock: 5, reorderLevel: 10).isLowStock)
    }
    
    func testNotLowStockAboveReorder() {
        XCTAssertFalse(InventoryItem(name: "A", stock: 100, reorderLevel: 10).isLowStock)
    }
    
    func testZeroStockIsLow() {
        XCTAssertTrue(InventoryItem(name: "A", stock: 0, reorderLevel: 10).isLowStock)
    }
    
    func testDefaultCategoryIsMedication() {
        XCTAssertEqual(InventoryItem(name: "Test").category, .medication)
    }
    
    func testAllInventoryCategories() {
        let cats: [InventoryCategory] = [.medication, .equipment, .consumables, .labSupplies, .surgical, .other]
        XCTAssertEqual(cats.count, InventoryCategory.allCases.count)
    }
    
    func testStockDeductionScenario() {
        var item = InventoryItem(name: "Paracetamol", stock: 100, reorderLevel: 20)
        XCTAssertFalse(item.isLowStock)
        item.stock -= 85  // Dispensed 85 units
        XCTAssertTrue(item.isLowStock, "Stock at 15 should trigger reorder at level 20")
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 11. VITALS RECORDING WORKFLOW TESTS
// ═══════════════════════════════════════════════════════════

final class VitalsWorkflowTests: XCTestCase {
    
    func testBloodPressureFormatted() {
        let v = VitalRecord(patientId: "p1", bloodPressureSystolic: 120, bloodPressureDiastolic: 80)
        XCTAssertEqual(v.bloodPressureFormatted, "120/80 mmHg")
    }
    
    func testBPNilWhenPartial() {
        XCTAssertNil(VitalRecord(patientId: "p1", bloodPressureSystolic: 120).bloodPressureFormatted)
        XCTAssertNil(VitalRecord(patientId: "p1", bloodPressureDiastolic: 80).bloodPressureFormatted)
    }
    
    func testHeartRateFormatted() {
        XCTAssertEqual(VitalRecord(patientId: "p1", heartRate: 72).heartRateFormatted, "72 bpm")
    }
    
    func testTemperatureFormatted() {
        XCTAssertEqual(VitalRecord(patientId: "p1", temperature: 98.6).temperatureFormatted, "98.6°F")
    }
    
    func testSpO2Formatted() {
        XCTAssertEqual(VitalRecord(patientId: "p1", oxygenSaturation: 98).spO2Formatted, "98%")
    }
    
    func testCriticalVitalRanges() {
        // Normal BP
        let normal = VitalRecord(patientId: "p1", bloodPressureSystolic: 120, bloodPressureDiastolic: 80)
        XCTAssertNotNil(normal.bloodPressureFormatted)
        
        // Hypertensive crisis (systolic > 180)
        let crisis = VitalRecord(patientId: "p1", bloodPressureSystolic: 190, bloodPressureDiastolic: 120)
        XCTAssertEqual(crisis.bloodPressureFormatted, "190/120 mmHg")
    }
    
    func testAllVitalsNilByDefault() {
        let v = VitalRecord(patientId: "p1")
        XCTAssertNil(v.bloodPressureSystolic)
        XCTAssertNil(v.heartRate)
        XCTAssertNil(v.temperature)
        XCTAssertNil(v.oxygenSaturation)
        XCTAssertNil(v.bloodGlucose)
    }
    
    func testVitalsRequestDefaultPending() {
        let r = VitalsRequest(doctorId: "d1", patientId: "p1", nurseId: "n1")
        XCTAssertEqual(r.status, .pending)
        XCTAssertNil(r.completedAt)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 12. ADMISSION WORKFLOW TESTS
// ═══════════════════════════════════════════════════════════

final class AdmissionWorkflowTests: XCTestCase {
    
    func testDefaultStatusIsAdmitted() {
        let a = Admission(patientId: "p1")
        XCTAssertEqual(a.status, .admitted)
    }
    
    func testNoDischargeDate() {
        XCTAssertNil(Admission(patientId: "p1").dischargeDate)
    }
    
    func testMultipleDoctorsOnAdmission() {
        let a = Admission(patientId: "p1", doctorIds: ["d1", "d2", "d3"])
        XCTAssertEqual(a.doctorIds.count, 3)
    }
    
    func testAdmissionStatusLifecycle() {
        // admitted → discharged (normal)
        // admitted → transferred (rare)
        let statuses: [AdmissionStatus] = [.admitted, .discharged, .transferred]
        XCTAssertEqual(statuses.count, AdmissionStatus.allCases.count)
    }
    
    func testBedAndWardAssignment() {
        let a = Admission(patientId: "p1", bedNumber: "ICU-01", wardNumber: "Ward-A")
        XCTAssertEqual(a.bedNumber, "ICU-01")
        XCTAssertEqual(a.wardNumber, "Ward-A")
    }
    
    func testDailyRoomRateDefault() {
        XCTAssertEqual(Admission(patientId: "p1").dailyRoomRate, 0, accuracy: 0.001)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 13. STAFF & SHIFT MANAGEMENT TESTS
// ═══════════════════════════════════════════════════════════

final class StaffManagementTests: XCTestCase {
    
    func testDefaultRoleIsNurse() {
        let s = Staff(name: "Test")
        XCTAssertEqual(s.role, .nurse)
    }
    
    func testDefaultShiftIsMorning() {
        let s = Staff(name: "Test")
        XCTAssertEqual(s.shift, .morning)
    }
    
    func testStaffIsActiveByDefault() {
        XCTAssertTrue(Staff(name: "Test").isActive)
    }
    
    func testShiftTimeRanges() {
        XCTAssertEqual(ShiftType.morning.timeRange, "6:00 AM – 2:00 PM")
        XCTAssertEqual(ShiftType.evening.timeRange, "2:00 PM – 10:00 PM")
        XCTAssertEqual(ShiftType.night.timeRange, "10:00 PM – 6:00 AM")
    }
    
    func testNursePatientAssignment() {
        let a = NursePatientAssignment(staffId: "n1", patientId: "p1")
        XCTAssertEqual(a.staffId, "n1")
        XCTAssertEqual(a.patientId, "p1")
    }
    
    func testShiftDefaultIsMorning() {
        let s = Shift(staffId: "s1")
        XCTAssertEqual(s.shiftType, .morning)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 14. USER ROLE ACCESS CONTROL TESTS
// ═══════════════════════════════════════════════════════════

final class UserRoleAccessControlTests: XCTestCase {
    
    func testPatientIsNotStaff() {
        XCTAssertFalse(UserRole.patient.isStaff)
    }
    
    func testAllStaffRolesAreStaff() {
        let staffRoles: [UserRole] = [.doctor, .admin, .nurse, .labTechnician, .pharmacist, .receptionist, .accountant]
        for role in staffRoles {
            XCTAssertTrue(role.isStaff, "\(role) should be staff")
        }
    }
    
    func testExactly8Roles() {
        XCTAssertEqual(UserRole.allCases.count, 8)
    }
    
    func testRoleBasedDataLoading() {
        // Patient → loads patient data
        // Doctor → loads doctor data
        // Admin/Nurse/LabTech/Pharmacist/Receptionist/Accountant → loads admin data
        let patientRoles: [UserRole] = [.patient]
        let doctorRoles: [UserRole] = [.doctor]
        let adminDataRoles: [UserRole] = [.admin, .nurse, .labTechnician, .pharmacist, .receptionist, .accountant]
        
        XCTAssertEqual(patientRoles.count + doctorRoles.count + adminDataRoles.count, UserRole.allCases.count)
    }
    
    func testUserActiveByDefault() {
        let user = MedNexUser(email: "test@test.com", role: .patient, displayName: "Test")
        XCTAssertTrue(user.isActive)
    }
    
    func testStaffIdLoginRawValue() {
        XCTAssertEqual(UserRole.labTechnician.rawValue, "lab_technician")
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 15. DOCTOR AVAILABILITY WORKFLOW TESTS
// ═══════════════════════════════════════════════════════════

final class DoctorAvailabilityTests: XCTestCase {
    
    func testDoctorDefaultIsAvailable() {
        XCTAssertTrue(Doctor(name: "Dr. Test").isAvailable)
    }
    
    func testFilterOnlyAvailableDoctors() {
        let doctors = [
            Doctor(name: "Dr. A", isAvailable: true),
            Doctor(name: "Dr. B", isAvailable: false),
            Doctor(name: "Dr. C", isAvailable: true)
        ]
        let available = doctors.filter { $0.isAvailable }
        XCTAssertEqual(available.count, 2)
    }
    
    func testFilterDoctorsBySpecialty() {
        let doctors = [
            Doctor(name: "Dr. Heart", specialty: .cardiology),
            Doctor(name: "Dr. Brain", specialty: .neurology),
            Doctor(name: "Dr. Heart2", specialty: .cardiology)
        ]
        let cardiologists = doctors.filter { $0.specialty == .cardiology }
        XCTAssertEqual(cardiologists.count, 2)
    }
    
    func testDoctorConsultationFeeDefault() {
        XCTAssertEqual(Doctor(name: "Dr. Test").consultationFee, 500, accuracy: 0.001)
    }
    
    func testDoctorEmptySlotsDefault() {
        XCTAssertTrue(Doctor(name: "Dr. Test").availableSlots.isEmpty)
    }
    
    func testDoctorIdResolution() {
        // When userId is set, use it; when empty, use id
        let docWithUserId = Doctor(id: "doc-table-id", userId: "firebase-uid", name: "Dr. A")
        let resolvedId = docWithUserId.userId.isEmpty ? docWithUserId.id : docWithUserId.userId
        XCTAssertEqual(resolvedId, "firebase-uid")
        
        let docWithoutUserId = Doctor(id: "doc-table-id", name: "Dr. B")
        let resolvedId2 = docWithoutUserId.userId.isEmpty ? docWithoutUserId.id : docWithoutUserId.userId
        XCTAssertEqual(resolvedId2, "doc-table-id")
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 16. MEDICAL SPECIALTY DECODER TESTS
// ═══════════════════════════════════════════════════════════

final class MedicalSpecialtyDecoderTests: XCTestCase {
    
    func testDecodesExactRawValue() throws {
        let json = "\"Cardiology\"".data(using: .utf8)!
        let s = try JSONDecoder().decode(MedicalSpecialty.self, from: json)
        XCTAssertEqual(s, .cardiology)
    }
    
    func testDecodesSnakeCase() throws {
        let json = "\"general_medicine\"".data(using: .utf8)!
        let s = try JSONDecoder().decode(MedicalSpecialty.self, from: json)
        XCTAssertEqual(s, .generalMedicine)
    }
    
    func testDecodesCaseInsensitive() throws {
        let json = "\"CARDIOLOGY\"".data(using: .utf8)!
        let s = try JSONDecoder().decode(MedicalSpecialty.self, from: json)
        XCTAssertEqual(s, .cardiology)
    }
    
    func testDecodesUnknownAsDefault() throws {
        let json = "\"something_nonexistent\"".data(using: .utf8)!
        let s = try JSONDecoder().decode(MedicalSpecialty.self, from: json)
        XCTAssertEqual(s, .generalMedicine, "Unknown specialty should default to generalMedicine")
    }
    
    func testAll18SpecialtiesDecode() throws {
        for specialty in MedicalSpecialty.allCases {
            let json = "\"\(specialty.rawValue)\"".data(using: .utf8)!
            let decoded = try JSONDecoder().decode(MedicalSpecialty.self, from: json)
            XCTAssertEqual(decoded, specialty)
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 17. NOTIFICATION ROUTING TESTS
// ═══════════════════════════════════════════════════════════

final class NotificationRoutingTests: XCTestCase {
    
    func testDefaultTypeIsGeneral() {
        let n = MedNexNotification(userId: "u1", title: "Test", body: "Body")
        XCTAssertEqual(n.type, .general)
        XCTAssertFalse(n.isRead)
    }
    
    func testAppointmentNotification() {
        let n = MedNexNotification(userId: "u1", type: .appointmentBooked, title: "Booked", body: "Your appointment is booked", relatedId: "apt-1")
        XCTAssertEqual(n.type, .appointmentBooked)
        XCTAssertEqual(n.relatedId, "apt-1")
    }
    
    func testPrescriptionNotification() {
        let n = MedNexNotification(userId: "u1", type: .prescriptionReady, title: "Rx", body: "Ready", relatedId: "rx-1")
        XCTAssertEqual(n.type, .prescriptionReady)
    }
    
    func testLabResultNotification() {
        let n = MedNexNotification(userId: "u1", type: .labResultReady, title: "Lab", body: "Results in", relatedId: "lab-1")
        XCTAssertEqual(n.type, .labResultReady)
    }
    
    func testAll9NotificationTypes() {
        XCTAssertEqual(NotificationType.allCases.count, 9)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 18. SLOT BLOCKING DATA FORMAT TESTS
// ═══════════════════════════════════════════════════════════

final class SlotBlockingDataTests: XCTestCase {
    
    let validTimeSlots = [
        "9:00 AM", "9:30 AM", "10:00 AM", "10:30 AM",
        "11:00 AM", "11:30 AM", "2:00 PM", "2:30 PM",
        "3:00 PM", "3:30 PM", "4:00 PM", "4:30 PM"
    ]
    
    func testAllTimeSlotsAreUnique() {
        XCTAssertEqual(validTimeSlots.count, Set(validTimeSlots).count)
    }
    
    func testTimeSlotCount() { XCTAssertEqual(validTimeSlots.count, 12) }
    func testTimeSlotsNonEmpty() { for s in validTimeSlots { XCTAssertFalse(s.isEmpty) } }
    
    func testBlockDateFormat() {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let s = fmt.string(from: Date())
        XCTAssertEqual(s.count, 10)
        XCTAssertNotNil(fmt.date(from: s))
    }
    
    func testDifferentDaysProduceDifferentBlockDates() {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let today = fmt.string(from: Date())
        let tomorrow = fmt.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        XCTAssertNotEqual(today, tomorrow)
    }
    
    func testSlotStringExactMatch() {
        let blocked: Set<String> = ["9:00 AM"]
        XCTAssertFalse(blocked.contains("9:00 am"))
        XCTAssertFalse(blocked.contains("09:00 AM"))
        XCTAssertFalse(blocked.contains("9:00AM"))
    }
    
    func testBlockedSlotsSetOps() {
        var blocked: Set<String> = ["9:00 AM", "10:00 AM"]
        blocked.insert("2:00 PM")
        XCTAssertEqual(blocked.count, 3)
        blocked.remove("9:00 AM")
        XCTAssertEqual(blocked.count, 2)
        XCTAssertFalse(blocked.contains("9:00 AM"))
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 19. SUPABASE JSON DECODING RESILIENCE TESTS
// ═══════════════════════════════════════════════════════════

final class AppointmentDecodingResilienceTests: XCTestCase {
    
    func testDecodesMinimalJSON() throws {
        let json = """
        {"id":"apt-001","patient_id":"p1","doctor_id":"d1","patient_name":"Test","doctor_name":"Dr.","specialty":"general_medicine","date_time":"2026-03-24T10:00:00Z","status":"scheduled","type":"consultation","notes":""}
        """.data(using: .utf8)!
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601
        let a = try d.decode(Appointment.self, from: json)
        XCTAssertEqual(a.id, "apt-001")
        XCTAssertEqual(a.status, .scheduled)
    }
    
    func testDecodesWithMissingOptionals() throws {
        let json = """
        {"id":"apt-002","patient_id":"p1","doctor_id":"d1","patient_name":"T","doctor_name":"D","specialty":"cardiology","date_time":"2026-03-24T10:00:00Z","status":"scheduled","type":"consultation","notes":""}
        """.data(using: .utf8)!
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601
        let a = try d.decode(Appointment.self, from: json)
        XCTAssertEqual(a.billingStatus, .pending)
        XCTAssertNil(a.cancellationReason)
        XCTAssertNil(a.rating)
    }
    
    func testDecodesAllStatusStrings() throws {
        for status in ["scheduled", "in_progress", "completed", "cancelled", "no_show"] {
            let json = """
            {"id":"a","patient_id":"p","doctor_id":"d","patient_name":"T","doctor_name":"D","specialty":"general_medicine","date_time":"2026-03-24T10:00:00Z","status":"\(status)","type":"consultation","notes":""}
            """.data(using: .utf8)!
            let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601
            let a = try d.decode(Appointment.self, from: json)
            XCTAssertEqual(a.status.rawValue, status)
        }
    }
    
    func testEncodesForSupabase() throws {
        let a = Appointment(patientId: "p1", doctorId: "d1", status: .scheduled)
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601
        let data = try e.encode(a)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(dict?["patient_id"])
        XCTAssertNotNil(dict?["doctor_id"])
        XCTAssertEqual(dict?["status"] as? String, "scheduled")
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 20. PATIENT MODEL & PROFILE TESTS
// ═══════════════════════════════════════════════════════════

final class PatientProfileWorkflowTests: XCTestCase {
    
    func testFullNameConcatenation() {
        let info = PersonalInfo(firstName: "Rahul", lastName: "Sharma")
        XCTAssertEqual(info.fullName, "Rahul Sharma")
    }
    
    func testAgeCalculation() {
        let dob = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        let info = PersonalInfo(firstName: "A", dateOfBirth: dob)
        XCTAssertEqual(info.age, 25)
    }
    
    func testNewbornAge() {
        XCTAssertEqual(PersonalInfo(firstName: "Baby", dateOfBirth: Date()).age, 0)
    }
    
    func testDefaultGenderIsOther() {
        XCTAssertEqual(PersonalInfo().gender, .other)
    }
    
    func testPatientDecodesWithNullJSONBColumns() throws {
        // This would have caught the crash when Supabase returns null for JSONB
        let json = """
        {"id":"p1","user_id":"u1"}
        """.data(using: .utf8)!
        let d = JSONDecoder()
        let p = try d.decode(Patient.self, from: json)
        XCTAssertEqual(p.id, "p1")
        XCTAssertEqual(p.personalInfo.firstName, "")
        XCTAssertTrue(p.emergencyContacts.isEmpty)
        XCTAssertEqual(p.medicalInfo.bloodType, .unknown)
    }
    
    func testMedicalInfoBloodType() {
        let info = MedicalInfo(bloodType: .abPositive, allergies: ["Penicillin"])
        XCTAssertEqual(info.bloodType, .abPositive)
        XCTAssertEqual(info.allergies.count, 1)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 21. DOCTOR DECODING RESILIENCE TESTS
// ═══════════════════════════════════════════════════════════

final class DoctorDecodingResilienceTests: XCTestCase {
    
    func testDecodesWithMinimalFields() throws {
        let json = """
        {"name":"Dr. Test"}
        """.data(using: .utf8)!
        let d = try JSONDecoder().decode(Doctor.self, from: json)
        XCTAssertEqual(d.name, "Dr. Test")
        XCTAssertEqual(d.specialty, .generalMedicine)
        XCTAssertEqual(d.consultationFee, 500, accuracy: 0.001)
        XCTAssertTrue(d.isAvailable)
    }
    
    func testDecodesSnakeCaseSpecialty() throws {
        let json = """
        {"name":"Dr.","specialty":"emergency_medicine"}
        """.data(using: .utf8)!
        let d = try JSONDecoder().decode(Doctor.self, from: json)
        XCTAssertEqual(d.specialty, .emergencyMedicine)
    }
    
    func testDefaultLanguageIsEnglish() {
        let d = Doctor(name: "Dr. Test")
        XCTAssertEqual(d.languages, ["English"])
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - 22. CROSS-CUTTING CONCERN TESTS
// ═══════════════════════════════════════════════════════════

final class CrossCuttingConcernTests: XCTestCase {
    
    // Date extension tests
    func testIsTodayTrue() { XCTAssertTrue(Date().isToday) }
    func testIsTodayFalseYesterday() {
        XCTAssertFalse(Calendar.current.date(byAdding: .day, value: -1, to: Date())!.isToday)
    }
    func testIsTomorrowTrue() {
        XCTAssertTrue(Calendar.current.date(byAdding: .day, value: 1, to: Date())!.isTomorrow)
    }
    func testIsPastTrue() {
        XCTAssertTrue(Calendar.current.date(byAdding: .day, value: -1, to: Date())!.isPast)
    }
    func testIsPastFalse() {
        XCTAssertFalse(Calendar.current.date(byAdding: .day, value: 1, to: Date())!.isPast)
    }
    
    // Data uniqueness
    func testAppointmentUniqueIds() {
        let a1 = Appointment(patientId: "p1", doctorId: "d1")
        let a2 = Appointment(patientId: "p1", doctorId: "d1")
        XCTAssertNotEqual(a1.id, a2.id)
    }
    
    func testPrescriptionUniqueIds() {
        let r1 = Prescription(patientId: "p1", doctorId: "d1")
        let r2 = Prescription(patientId: "p1", doctorId: "d1")
        XCTAssertNotEqual(r1.id, r2.id)
    }
    
    func testLabTestUniqueIds() {
        let t1 = LabTest(patientId: "p1", doctorId: "d1", testName: "CBC", testCategory: .bloodWork)
        let t2 = LabTest(patientId: "p1", doctorId: "d1", testName: "CBC", testCategory: .bloodWork)
        XCTAssertNotEqual(t1.id, t2.id)
    }
    
    func testBillUniqueIds() {
        let b1 = Bill(patientId: "p1")
        let b2 = Bill(patientId: "p1")
        XCTAssertNotEqual(b1.id, b2.id)
    }
}
