//
//  AdminAddStaffView.swift
//  MedNex
//

import SwiftUI

struct AdminAddStaffView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    
    @State private var name = ""
    @State private var email = ""
    @State private var staffId = ""
    @State private var password = ""
    @State private var role: UserRole = .doctor
    
    // Pickers based on role
    @State private var selectedDepartmentId: String = ""
    @State private var shift: ShiftType = .morning
    
    // Additional fields based on role
    @State private var specialization = ""
    @State private var phone = ""
    @State private var qualifications = ""
    
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    
    private var isFormValid: Bool {
        let isDeptValid = role == .doctor ? !selectedDepartmentId.isEmpty : true
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !staffId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 8 &&
        isDeptValid
    }
    
    // Only show certain roles to admin (e.g., doctor, nurse, labTechnician)
    private let availableRoles: [UserRole] = [
        .doctor, .nurse, .labTechnician
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Staff ID (e.g., DOC006)", text: $staffId)
                        .textInputAutocapitalization(.characters)
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                    
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                
                Section("Authentication") {
                    SecureField("Password (min 8 characters)", text: $password)
                        .textContentType(.newPassword)
                }
                
                Section("Role & Assignment") {
                    Picker("Role", selection: $role) {
                        ForEach(availableRoles, id: \.self) { roleType in
                            Text(roleType.rawValue.capitalized).tag(roleType)
                        }
                    }
                    
                    if role == .doctor {
                        Picker("Department", selection: $selectedDepartmentId) {
                            Text("Select Department").tag("")
                            ForEach(dataStore.departments) { dept in
                                Text(dept.name).tag(dept.id)
                            }
                        }
                    }
                    
                    Picker("Shift", selection: $shift) {
                        ForEach(ShiftType.allCases, id: \.self) { shiftType in
                            Text(shiftType.rawValue).tag(shiftType)
                        }
                    }
                }
                
                Section("Additional Details (Optional)") {
                    if role == .doctor {
                        TextField("Specialization (e.g., Cardiology)", text: $specialization)
                    }
                    TextField("Qualifications (e.g., MD, MBBS)", text: $qualifications)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Add Staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task { await submitForm() }
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.1).ignoresSafeArea()
                        ProgressView("Creating Staff...")
                            .padding()
                            .background(Material.regular)
                            .cornerRadius(12)
                    }
                }
            }
            .onAppear {
                if let firstDept = dataStore.departments.first {
                    selectedDepartmentId = firstDept.id
                }
            }
        }
    }
    
    private func submitForm() async {
        isSubmitting = true
        errorMessage = nil
        
        do {
            #if canImport(FirebaseAuth)
            let authService = FirebaseAuthService()
            
            // 1. Create User via off-session Firebase App (which also creates users table record)
            let newUser = try await authService.createStaffUserOffSession(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                role: role
            )
            
            // 2. Resolve department name
            let deptName = dataStore.departments.first(where: { $0.id == selectedDepartmentId })?.name
            
            // 3. Create Staff record
            // If specialization is empty for a doctor, use department name as fallback
            let resolvedSpecialization: String? = {
                if role == .doctor {
                    let spec = specialization.trimmingCharacters(in: .whitespacesAndNewlines)
                    return spec.isEmpty ? deptName : spec
                }
                return nil
            }()
            
            let updatedDepartmentId = role == .doctor ? selectedDepartmentId : nil
            let updatedDepartmentName = role == .doctor ? deptName : nil
            
            let newStaff = Staff(
                id: staffId.trimmingCharacters(in: .whitespacesAndNewlines),
                userId: newUser.id,
                name: newUser.displayName,
                role: role,
                departmentId: updatedDepartmentId,
                departmentName: updatedDepartmentName,
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                email: newUser.email,
                shift: shift,
                joinDate: Date(),
                isActive: true,
                qualifications: qualifications.trimmingCharacters(in: .whitespacesAndNewlines),
                specialization: resolvedSpecialization,
                profileImageURL: nil
            )
            
            // 4. Save to Database via AdminRepository (staff table only — doctors table is deprecated)
            #if canImport(Supabase)
            try await AdminRepository.shared.createStaff(newStaff)
            #endif
            
            // 5. Update Local Cache
            await MainActor.run {
                dataStore.staff.append(newStaff)
                // doctors is computed from staff — no separate append needed
                dismiss()
            }
            
            #else
            throw NSError(domain: "AddStaff", code: 2, userInfo: [NSLocalizedDescriptionKey: "Firebase Auth not available."])
            #endif
            
            
        } catch let AuthError.weakPassword(reasons) {
            errorMessage = "Weak password: " + reasons.joined(separator: ", ")
        } catch let error as NSError {
            errorMessage = "Failed to create staff: \(error.localizedDescription)"
            if let reason = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String {
                errorMessage! += "\n\(reason)"
            }
        }
        
        isSubmitting = false
    }
}
