//
//  MockDataService.swift
//  MedNex
//
//  Provides sample data for all entities used across the app.

import Foundation

enum MockDataService {
    
    // MARK: - Demo Credentials
    struct DemoAccount {
        let email: String
        let password: String
        let staffId: String?
        let role: UserRole
        let displayName: String
    }
    
    static let demoAccounts: [DemoAccount] = [
        DemoAccount(email: "demo@mednex.com", password: "Demo@123", staffId: nil, role: .patient, displayName: "Alex Johnson"),
        DemoAccount(email: "dr.smith@mednex.com", password: "Doctor@123", staffId: "DOC001", role: .doctor, displayName: "Dr. Sarah Smith"),
        DemoAccount(email: "admin@mednex.com", password: "Admin@123", staffId: "ADM001", role: .admin, displayName: "James Wilson"),
        DemoAccount(email: "nurse@mednex.com", password: "Nurse@123", staffId: "NRS001", role: .nurse, displayName: "Emily Davis"),
        DemoAccount(email: "lab@mednex.com", password: "Lab@1234", staffId: "LAB001", role: .labTechnician, displayName: "Michael Chen"),
        DemoAccount(email: "pharma@mednex.com", password: "Pharma@1", staffId: "PHR001", role: .pharmacist, displayName: "Lisa Rodriguez"),
    ]
    
    // MARK: - Sample Users
    static let sampleUsers: [MedNexUser] = demoAccounts.map { account in
        MedNexUser(
            id: UUID().uuidString,
            email: account.email,
            role: account.role,
            displayName: account.displayName,
            createdAt: Date().adding(days: -90),
            lastLogin: Date()
        )
    }
    
    // MARK: - Sample Doctors
    static let sampleDoctors: [Doctor] = [
        Doctor(id: "doc1", userId: "u_doc1", name: "Dr. Sarah Smith", specialty: .generalMedicine, experience: 12, licenseNumber: "MED-2014-001", consultationFee: 500, departmentId: "dept1", rating: 4.8, totalRatings: 245, bio: "Experienced general physician with a focus on preventive medicine.", education: "MBBS, MD - General Medicine", languages: ["English", "Hindi"]),
        Doctor(id: "doc2", userId: "u_doc2", name: "Dr. Rajesh Patel", specialty: .cardiology, experience: 18, licenseNumber: "MED-2008-042", consultationFee: 1200, departmentId: "dept2", rating: 4.9, totalRatings: 312, bio: "Leading cardiologist specializing in interventional procedures.", education: "MBBS, DM - Cardiology", languages: ["English", "Hindi", "Gujarati"]),
        Doctor(id: "doc3", userId: "u_doc3", name: "Dr. Priya Sharma", specialty: .pediatrics, experience: 8, licenseNumber: "MED-2018-089", consultationFee: 600, departmentId: "dept3", rating: 4.7, totalRatings: 178, bio: "Pediatrician passionate about child health and development.", education: "MBBS, MD - Pediatrics", languages: ["English", "Hindi"]),
        Doctor(id: "doc4", userId: "u_doc4", name: "Dr. James Lee", specialty: .orthopedics, experience: 15, licenseNumber: "MED-2011-033", consultationFee: 1000, departmentId: "dept4", rating: 4.6, totalRatings: 198, bio: "Orthopedic surgeon with expertise in joint replacement.", education: "MBBS, MS - Orthopedics", languages: ["English"]),
        Doctor(id: "doc5", userId: "u_doc5", name: "Dr. Aisha Khan", specialty: .dermatology, experience: 10, licenseNumber: "MED-2016-067", consultationFee: 800, departmentId: "dept5", rating: 4.8, totalRatings: 267, bio: "Dermatologist specializing in cosmetic and clinical treatments.", education: "MBBS, MD - Dermatology", languages: ["English", "Urdu"]),
        Doctor(id: "doc6", userId: "u_doc6", name: "Dr. David Brown", specialty: .neurology, experience: 20, licenseNumber: "MED-2006-012", consultationFee: 1500, departmentId: "dept6", rating: 4.9, totalRatings: 156, bio: "Senior neurologist focused on neurodegenerative disorders.", education: "MBBS, DM - Neurology", languages: ["English"]),
    ]
    
    // MARK: - Sample Departments
    static let sampleDepartments: [Department] = [
        Department(id: "dept1", name: "General Medicine", headDoctorId: "doc1", headDoctorName: "Dr. Sarah Smith", staffCount: 12, location: "Building A, Floor 2", description: "Primary care and internal medicine"),
        Department(id: "dept2", name: "Cardiology", headDoctorId: "doc2", headDoctorName: "Dr. Rajesh Patel", staffCount: 8, location: "Building B, Floor 3", description: "Heart and cardiovascular system"),
        Department(id: "dept3", name: "Pediatrics", headDoctorId: "doc3", headDoctorName: "Dr. Priya Sharma", staffCount: 10, location: "Building A, Floor 3", description: "Child and adolescent health"),
        Department(id: "dept4", name: "Orthopedics", headDoctorId: "doc4", headDoctorName: "Dr. James Lee", staffCount: 7, location: "Building C, Floor 1", description: "Musculoskeletal system"),
        Department(id: "dept5", name: "Dermatology", headDoctorId: "doc5", headDoctorName: "Dr. Aisha Khan", staffCount: 5, location: "Building A, Floor 4", description: "Skin, hair, and nail conditions"),
        Department(id: "dept6", name: "Neurology", headDoctorId: "doc6", headDoctorName: "Dr. David Brown", staffCount: 6, location: "Building B, Floor 4", description: "Brain and nervous system"),
    ]
    
    // MARK: - Sample Patient
    static let samplePatient = Patient(
        id: "pat1",
        userId: "u_pat1",
        personalInfo: PersonalInfo(
            firstName: "Alex",
            lastName: "Johnson",
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1990, month: 5, day: 15))!,
            gender: .male,
            phone: "+1 (555) 123-4567",
            address: "123 Main Street",
            city: "San Francisco",
            state: "California",
            zipCode: "94102"
        ),
        emergencyContacts: [
            EmergencyContact(name: "Maria Johnson", relationship: "Spouse", phone: "+1 (555) 987-6543")
        ],
        medicalInfo: MedicalInfo(
            bloodType: .oPositive,
            allergies: ["Penicillin", "Peanuts"],
            chronicConditions: ["Mild Asthma"],
            currentMedications: ["Albuterol Inhaler"],
            height: 178,
            weight: 75
        )
    )
    
    // MARK: - Sample Appointments
    static let sampleAppointments: [Appointment] = [
        Appointment(id: "appt1", patientId: "pat1", patientName: "Alex Johnson", doctorId: "doc1", doctorName: "Dr. Sarah Smith", specialty: .generalMedicine, dateTime: Date().adding(days: 1).adding(hours: 2), status: .scheduled, type: .consultation),
        Appointment(id: "appt2", patientId: "pat1", patientName: "Alex Johnson", doctorId: "doc2", doctorName: "Dr. Rajesh Patel", specialty: .cardiology, dateTime: Date().adding(days: 3), status: .scheduled, type: .checkup),
        Appointment(id: "appt3", patientId: "pat1", patientName: "Alex Johnson", doctorId: "doc3", doctorName: "Dr. Priya Sharma", specialty: .pediatrics, dateTime: Date().adding(days: -7), status: .completed, type: .consultation, notes: "Patient reported mild fever. Prescribed antipyretics."),
        Appointment(id: "appt4", patientId: "pat1", patientName: "Alex Johnson", doctorId: "doc5", doctorName: "Dr. Aisha Khan", specialty: .dermatology, dateTime: Date().adding(days: -14), status: .completed, type: .followUp, billingStatus: .paid),
    ]
    
    // MARK: - Sample Prescriptions
    static let samplePrescriptions: [Prescription] = [
        Prescription(
            id: "rx1",
            appointmentId: "appt3",
            patientId: "pat1",
            patientName: "Alex Johnson",
            doctorId: "doc3",
            doctorName: "Dr. Priya Sharma",
            medicines: [
                PrescribedMedicine(name: "Paracetamol", dosage: "500mg", frequency: .thriceDaily, duration: "5 days", instructions: "Take after meals"),
                PrescribedMedicine(name: "Cetirizine", dosage: "10mg", frequency: .onceDaily, duration: "7 days", instructions: "Take at bedtime"),
            ],
            diagnosis: "Upper Respiratory Tract Infection",
            createdAt: Date().adding(days: -7)
        ),
    ]
    
    // MARK: - Sample Lab Tests
    static let sampleLabTests: [LabTest] = [
        LabTest(
            id: "lab1",
            patientId: "pat1",
            patientName: "Alex Johnson",
            doctorId: "doc1",
            doctorName: "Dr. Sarah Smith",
            testName: "Complete Blood Count (CBC)",
            testCategory: .bloodWork,
            status: .completed,
            priority: .routine,
            results: [
                LabTestResult(parameterName: "Hemoglobin", value: "14.2", unit: "g/dL", normalRange: "13.5-17.5", isAbnormal: false),
                LabTestResult(parameterName: "WBC Count", value: "7,500", unit: "cells/mcL", normalRange: "4,500-11,000", isAbnormal: false),
                LabTestResult(parameterName: "Platelet Count", value: "250,000", unit: "cells/mcL", normalRange: "150,000-400,000", isAbnormal: false),
            ],
            orderedAt: Date().adding(days: -10),
            completedAt: Date().adding(days: -8)
        ),
        LabTest(
            id: "lab2",
            patientId: "pat1",
            patientName: "Alex Johnson",
            doctorId: "doc2",
            doctorName: "Dr. Rajesh Patel",
            testName: "Lipid Profile",
            testCategory: .bloodWork,
            status: .pending,
            priority: .routine,
            orderedAt: Date()
        ),
        LabTest(
            id: "lab3",
            patientId: "pat2",
            patientName: "Emily Davis",
            doctorId: "doc3",
            doctorName: "Dr. Priya Sharma",
            testName: "Urinalysis Routine",
            testCategory: .urinalysis,
            status: .processing,
            priority: .urgent,
            orderedAt: Date().adding(hours: -2)
        ),
        LabTest(
            id: "lab4",
            patientId: "pat3",
            patientName: "Michael Chen",
            doctorId: "doc4",
            doctorName: "Dr. James Lee",
            testName: "Thyroid Panel (TSH, T3, T4)",
            testCategory: .bloodWork,
            status: .pending,
            priority: .routine,
            orderedAt: Date().adding(days: -1)
        ),
        LabTest(
            id: "lab5",
            patientId: "pat4",
            patientName: "Lisa Rodriguez",
            doctorId: "doc5",
            doctorName: "Dr. Aisha Khan",
            testName: "Vitamin D Test",
            testCategory: .bloodWork,
            status: .pending,
            priority: .routine,
            orderedAt: Date().adding(hours: -5)
        ),
    ]
    
    // MARK: - Sample Vital Records
    static func sampleVitalRecords() -> [VitalRecord] {
        (0..<14).map { dayOffset in
            VitalRecord(
                patientId: "pat1",
                recordedBy: "NRS001",
                timestamp: Date().adding(days: -dayOffset),
                bloodPressureSystolic: Double.random(in: 115...135),
                bloodPressureDiastolic: Double.random(in: 70...85),
                heartRate: Double.random(in: 65...85),
                temperature: Double.random(in: 97.8...99.2),
                oxygenSaturation: Double.random(in: 96...99),
                weight: 75 + Double.random(in: -0.5...0.5)
            )
        }
    }
    
    // MARK: - Sample Bills
    static let sampleBills: [Bill] = [
        Bill(
            id: "bill1",
            appointmentId: "appt3",
            patientId: "pat1",
            patientName: "Alex Johnson",
            items: [
                BillItem(description: "Consultation Fee", quantity: 1, unitPrice: 600, total: 600),
                BillItem(description: "Lab - CBC Test", quantity: 1, unitPrice: 350, total: 350),
            ],
            totalAmount: 950,
            paidAmount: 950,
            paymentMode: .card,
            status: .paid,
            createdAt: Date().adding(days: -7),
            paidAt: Date().adding(days: -7)
        ),
        Bill(
            id: "bill2",
            appointmentId: "appt4",
            patientId: "pat1",
            patientName: "Alex Johnson",
            items: [
                BillItem(description: "Follow-up Consultation", quantity: 1, unitPrice: 800, total: 800),
            ],
            totalAmount: 800,
            paidAmount: 800,
            paymentMode: .upi,
            status: .paid,
            createdAt: Date().adding(days: -14),
            paidAt: Date().adding(days: -14)
        ),
    ]
    
    // MARK: - Sample Notifications
    static let sampleNotifications: [MedNexNotification] = [
        MedNexNotification(userId: "u_pat1", type: .appointmentReminder, title: "Upcoming Appointment", body: "Your appointment with Dr. Sarah Smith is tomorrow at 10:00 AM.", createdAt: Date().adding(hours: -2)),
        MedNexNotification(userId: "u_pat1", type: .labResultReady, title: "Lab Results Ready", body: "Your CBC test results are now available.", isRead: true, createdAt: Date().adding(days: -2)),
        MedNexNotification(userId: "u_pat1", type: .prescriptionReady, title: "Prescription Ready", body: "Your prescription from Dr. Priya Sharma is ready for pickup.", isRead: true, createdAt: Date().adding(days: -7)),
    ]
    
    // MARK: - Sample Staff
    static let sampleStaff: [Staff] = [
        Staff(name: "Emily Davis", role: .nurse, departmentId: "dept1", departmentName: "General Medicine", phone: "+1 (555) 234-5678", email: "nurse@mednex.com", shift: .morning, qualifications: "BSN, RN"),
        Staff(name: "Michael Chen", role: .labTechnician, departmentId: "dept1", departmentName: "Pathology", phone: "+1 (555) 345-6789", email: "lab@mednex.com", shift: .morning, qualifications: "MLT Certified"),
        Staff(name: "Lisa Rodriguez", role: .pharmacist, departmentId: "dept1", departmentName: "Pharmacy", phone: "+1 (555) 456-7890", email: "pharma@mednex.com", shift: .morning, qualifications: "PharmD"),
        Staff(name: "Kevin Park", role: .receptionist, departmentId: "dept1", departmentName: "Front Desk", phone: "+1 (555) 567-8901", email: "reception@mednex.com", shift: .morning),
    ]
    
    // MARK: - Sample Inventory
    static let sampleInventory: [InventoryItem] = [
        InventoryItem(name: "Paracetamol 500mg", category: .medication, stock: 500, reorderLevel: 100, unitPrice: 2.5, supplier: "PharmaCorp"),
        InventoryItem(name: "Amoxicillin 250mg", category: .medication, stock: 200, reorderLevel: 50, unitPrice: 5.0, supplier: "PharmaCorp"),
        InventoryItem(name: "Surgical Gloves (Box)", category: .consumables, stock: 15, reorderLevel: 20, unitPrice: 12.0, supplier: "MedSupply Inc"),
        InventoryItem(name: "Blood Collection Tubes", category: .labSupplies, stock: 350, reorderLevel: 100, unitPrice: 1.5, supplier: "LabTech Supplies"),
        InventoryItem(name: "Digital Thermometer", category: .equipment, stock: 8, reorderLevel: 5, unitPrice: 25.0, supplier: "MedEquip Co"),
    ]
    
    // MARK: - Drug Database
    static let drugDatabase: [Medicine] = [
        Medicine(name: "Paracetamol", genericName: "Acetaminophen", category: "Analgesic", manufacturer: "GSK", dosageForms: ["Tablet", "Syrup", "Injection"], strengths: ["250mg", "500mg", "650mg"]),
        Medicine(name: "Amoxicillin", genericName: "Amoxicillin", category: "Antibiotic", manufacturer: "Cipla", dosageForms: ["Capsule", "Syrup"], strengths: ["250mg", "500mg"]),
        Medicine(name: "Cetirizine", genericName: "Cetirizine HCl", category: "Antihistamine", manufacturer: "Dr Reddy's", dosageForms: ["Tablet", "Syrup"], strengths: ["5mg", "10mg"]),
        Medicine(name: "Metformin", genericName: "Metformin HCl", category: "Antidiabetic", manufacturer: "Sun Pharma", dosageForms: ["Tablet"], strengths: ["500mg", "850mg", "1000mg"]),
        Medicine(name: "Atorvastatin", genericName: "Atorvastatin Calcium", category: "Statin", manufacturer: "Pfizer", dosageForms: ["Tablet"], strengths: ["10mg", "20mg", "40mg"]),
        Medicine(name: "Omeprazole", genericName: "Omeprazole", category: "PPI", manufacturer: "AstraZeneca", dosageForms: ["Capsule"], strengths: ["20mg", "40mg"]),
        Medicine(name: "Amlodipine", genericName: "Amlodipine Besylate", category: "Antihypertensive", manufacturer: "Pfizer", dosageForms: ["Tablet"], strengths: ["2.5mg", "5mg", "10mg"]),
        Medicine(name: "Azithromycin", genericName: "Azithromycin", category: "Antibiotic", manufacturer: "Zydus", dosageForms: ["Tablet", "Syrup"], strengths: ["250mg", "500mg"]),
    ]
}
