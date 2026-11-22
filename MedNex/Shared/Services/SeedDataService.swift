//
//  SeedDataService.swift
//  MedNex
//
//  One-time seeder that creates all demo accounts in Firebase Auth
//  and inserts their profiles + sample data into Supabase.
//  Trigger via: SeedDataService.shared.seedAllDemoAccounts()

#if canImport(FirebaseAuth)
import Foundation
import FirebaseAuth

final class SeedDataService {
    static let shared = SeedDataService()
    private let log = LoggingService.shared
    
    private init() {}
    
    // MARK: - Demo Accounts (matching MockDataService.demoAccounts)
    
    struct SeedAccount {
        let email: String
        let password: String
        let staffId: String?
        let role: UserRole
        let displayName: String
    }
    
    static let accounts: [SeedAccount] = [
        SeedAccount(email: "demo@mednex.com", password: "Demo@123", staffId: nil, role: .patient, displayName: "Alex Johnson"),
        SeedAccount(email: "dr.smith@mednex.com", password: "Doctor@123", staffId: "DOC001", role: .doctor, displayName: "Dr. Sarah Smith"),
        SeedAccount(email: "admin@mednex.com", password: "Admin@123", staffId: "ADM001", role: .admin, displayName: "James Wilson"),
        SeedAccount(email: "nurse@mednex.com", password: "Nurse@123", staffId: "NRS001", role: .nurse, displayName: "Emily Davis"),
        SeedAccount(email: "lab@mednex.com", password: "Lab@1234", staffId: "LAB001", role: .labTechnician, displayName: "Michael Chen"),
        SeedAccount(email: "pharma@mednex.com", password: "Pharma@1", staffId: "PHR001", role: .pharmacist, displayName: "Lisa Rodriguez"),
    ]
    
    // MARK: - Seed All Accounts
    
    /// Creates all demo users in Firebase Auth and Supabase.
    /// Safe to call multiple times — skips accounts that already exist.
    func seedAllDemoAccounts() async {
        log.auth("🌱 Starting demo account seeding...")
        print("🌱 Starting demo account seeding...")
        
        for account in Self.accounts {
            await seedAccount(account)
        }
        
        log.auth("🌱 Demo account seeding complete!")
        print("🌱 Demo account seeding complete!")
        print("")
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║                    MedNex Demo Credentials                  ║")
        print("╠══════════════════════════════════════════════════════════════╣")
        print("║ Role         │ Email                  │ Password            ║")
        print("╠══════════════╪════════════════════════╪═════════════════════╣")
        print("║ Patient      │ demo@mednex.com        │ Demo@123            ║")
        print("║ Doctor       │ dr.smith@mednex.com    │ Doctor@123          ║")
        print("║ Admin        │ admin@mednex.com       │ Admin@123           ║")
        print("║ Nurse        │ nurse@mednex.com       │ Nurse@123           ║")
        print("║ Lab Tech     │ lab@mednex.com         │ Lab@1234            ║")
        print("║ Pharmacist   │ pharma@mednex.com      │ Pharma@1            ║")
        print("╚══════════════════════════════════════════════════════════════╝")
        print("")
        print("Staff IDs: DOC001, ADM001, NRS001, LAB001, PHR001")
    }
    
    // MARK: - Seed Individual Account
    
    private func seedAccount(_ account: SeedAccount) async {
        do {
            // Try to create in Firebase
            let result: AuthDataResult
            do {
                result = try await Auth.auth().createUser(withEmail: account.email, password: account.password)
                
                // Set display name
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = account.displayName
                try await changeRequest.commitChanges()
                
                print("  ✅ Firebase: Created \(account.email)")
            } catch let error as NSError {
                if error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    print("  ⏭️ Firebase: \(account.email) already exists — skipping")
                    // Sign in to get UID for Supabase profile
                    let signInResult = try await Auth.auth().signIn(withEmail: account.email, password: account.password)
                    // Still try to create Supabase profile in case it's missing
                    await createSupabaseProfile(uid: signInResult.user.uid, account: account)
                    return
                } else {
                    print("  ❌ Firebase: Failed for \(account.email): \(error.localizedDescription)")
                    return
                }
            }
            
            // Create Supabase profile
            await createSupabaseProfile(uid: result.user.uid, account: account)
            
        } catch {
            print("  ❌ Error seeding \(account.email): \(error.localizedDescription)")
        }
    }
    
    private func createSupabaseProfile(uid: String, account: SeedAccount) async {
        #if canImport(Supabase)
        let user = MedNexUser(
            id: uid,
            email: account.email,
            role: account.role,
            displayName: account.displayName,
            createdAt: Date(),
            lastLogin: Date()
        )
        
        do {
            try await SupabaseService.shared.createUserProfile(user)
            print("  ✅ Supabase: Profile created for \(account.email)")
        } catch {
            // Might already exist — try updating instead
            do {
                try await SupabaseService.shared.updateUserProfile(user)
                print("  ⏭️ Supabase: Profile updated for \(account.email)")
            } catch {
                print("  ⚠️ Supabase: Profile for \(account.email): \(error.localizedDescription)")
            }
        }
        
        // Seed role-specific data
        await seedRoleData(uid: uid, account: account)
        #endif
    }
    
    // MARK: - Seed Role-Specific Data
    
    #if canImport(Supabase)
    private func seedRoleData(uid: String, account: SeedAccount) async {
        let supabase = SupabaseService.shared
        
        switch account.role {
        case .patient:
            await seedPatientData(uid: uid, supabase: supabase)
        case .doctor:
            await seedDoctorData(uid: uid, account: account, supabase: supabase)
        case .admin:
            await seedAdminData(uid: uid, account: account, supabase: supabase)
        case .nurse, .labTechnician, .pharmacist, .receptionist, .accountant:
            await seedStaffData(uid: uid, account: account, supabase: supabase)
        }
    }
    
    private func seedPatientData(uid: String, supabase: SupabaseService) async {
        // Insert a patient record
        struct PatientSeed: Encodable {
            let id: String
            let user_id: String
            let full_name: String
            let date_of_birth: String
            let gender: String
            let blood_type: String
            let phone: String
            let emergency_contact_name: String
            let emergency_contact_phone: String
            let insurance_provider: String
            let insurance_policy_number: String
            let allergies: [String]
            let chronic_conditions: [String]
        }
        
        let patient = PatientSeed(
            id: uid,
            user_id: uid,
            full_name: "Alex Johnson",
            date_of_birth: "1992-06-15",
            gender: "male",
            blood_type: "O+",
            phone: "+91 98765 43210",
            emergency_contact_name: "Maria Johnson",
            emergency_contact_phone: "+91 98765 43211",
            insurance_provider: "MediCare Plus",
            insurance_policy_number: "MCP-2024-78901",
            allergies: ["Penicillin", "Peanuts"],
            chronic_conditions: ["Mild Asthma"]
        )
        
        do {
            try await supabase.insert(patient, into: "patients")
            print("  ✅ Supabase: Patient record seeded")
        } catch {
            print("  ⚠️ Patient record: \(error.localizedDescription)")
        }
    }
    
    private func seedDoctorData(uid: String, account: SeedAccount, supabase: SupabaseService) async {
        struct DoctorSeed: Encodable {
            let id: String
            let user_id: String
            let name: String
            let specialty: String
            let experience: Int
            let license_number: String
            let consultation_fee: Double
            let department_id: String
            let rating: Double
            let total_ratings: Int
            let bio: String
            let education: String
            let languages: [String]
            let is_available: Bool
        }
        
        let doctor = DoctorSeed(
            id: "doc_\(uid.prefix(8))",
            user_id: uid,
            name: account.displayName,
            specialty: "general_medicine",
            experience: 12,
            license_number: "MED-2014-001",
            consultation_fee: 500,
            department_id: "dept1",
            rating: 4.8,
            total_ratings: 245,
            bio: "Experienced general physician with a focus on preventive medicine.",
            education: "MBBS, MD - General Medicine",
            languages: ["English", "Hindi"],
            is_available: true
        )
        
        do {
            try await supabase.insert(doctor, into: "doctors")
            print("  ✅ Supabase: Doctor record seeded")
        } catch {
            print("  ⚠️ Doctor record: \(error.localizedDescription)")
        }
        
        // Also create staff record for doctor
        await seedStaffData(uid: uid, account: account, supabase: supabase)
    }
    
    private func seedAdminData(uid: String, account: SeedAccount, supabase: SupabaseService) async {
        await seedStaffData(uid: uid, account: account, supabase: supabase)
    }
    
    private func seedStaffData(uid: String, account: SeedAccount, supabase: SupabaseService) async {
        struct StaffSeed: Encodable {
            let id: String
            let user_id: String
            let name: String
            let email: String
            let role: String
            let department_id: String
            let department_name: String
            let phone: String
            let is_active: Bool
            let shift: String
        }
        
        let staffId = account.staffId ?? "STAFF_\(uid.prefix(6))"
        let deptName = departmentForRole(account.role)
        
        let staffRecord = StaffSeed(
            id: staffId,
            user_id: uid,
            name: account.displayName,
            email: account.email,
            role: account.role.rawValue,
            department_id: deptIdForRole(account.role),
            department_name: deptName,
            phone: "+91 98765 \(String(format: "%05d", Int.random(in: 10000...99999)))",
            is_active: true,
            shift: "Morning"
        )
        
        do {
            try await supabase.insert(staffRecord, into: "staff")
            print("  ✅ Supabase: Staff record seeded for \(account.displayName)")
        } catch {
            print("  ⚠️ Staff record: \(error.localizedDescription)")
        }
    }
    
    private func departmentForRole(_ role: UserRole) -> String {
        switch role {
        case .doctor: return "General Medicine"
        case .nurse: return "Nursing"
        case .admin: return "Administration"
        case .labTechnician: return "Pathology"
        case .pharmacist: return "Pharmacy"
        case .receptionist: return "Front Desk"
        case .accountant: return "Finance"
        case .patient: return ""
        }
    }
    
    private func deptIdForRole(_ role: UserRole) -> String {
        switch role {
        case .doctor: return "dept1"
        case .nurse: return "dept1"
        case .admin: return "dept10"
        case .labTechnician: return "dept7"
        case .pharmacist: return "dept8"
        case .receptionist: return "dept10"
        case .accountant: return "dept10"
        case .patient: return ""
        }
    }
    #endif
}
#endif
