//
//  EditPatientProfileView.swift
//  MedNex
//

import SwiftUI

struct EditPatientProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    
    @State private var draftPatient: Patient
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showError = false
    
    // Extracted bindings for convenience
    @State private var firstName: String
    @State private var lastName: String
    @State private var phone: String
    @State private var address: String
    @State private var city: String
    @State private var dateOfBirth: Date
    @State private var gender: Gender
    
    @State private var bloodType: BloodType
    @State private var allergiesRaw: String
    @State private var conditionsRaw: String
    @State private var heightRaw: String
    @State private var weightRaw: String
    
    init(patient: Patient) {
        _draftPatient = State(initialValue: patient)
        
        _firstName = State(initialValue: patient.personalInfo.firstName)
        _lastName = State(initialValue: patient.personalInfo.lastName)
        _phone = State(initialValue: patient.personalInfo.phone)
        _address = State(initialValue: patient.personalInfo.address)
        _city = State(initialValue: patient.personalInfo.city)
        _dateOfBirth = State(initialValue: patient.personalInfo.dateOfBirth)
        _gender = State(initialValue: patient.personalInfo.gender)
        
        _bloodType = State(initialValue: patient.medicalInfo.bloodType)
        _allergiesRaw = State(initialValue: patient.medicalInfo.allergies.joined(separator: ", "))
        _conditionsRaw = State(initialValue: patient.medicalInfo.chronicConditions.joined(separator: ", "))
        
        if let h = patient.medicalInfo.height {
            _heightRaw = State(initialValue: String(format: "%.1f", h))
        } else {
            _heightRaw = State(initialValue: "")
        }
        
        if let w = patient.medicalInfo.weight {
            _weightRaw = State(initialValue: String(format: "%.1f", w))
        } else {
            _weightRaw = State(initialValue: "")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { g in
                            Text(g.displayName).tag(g)
                        }
                    }
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $address)
                    TextField("City", text: $city)
                }
                
                Section(header: Text("Medical Information")) {
                    Picker("Blood Type", selection: $bloodType) {
                        ForEach(BloodType.allCases, id: \.self) { bt in
                            Text(bt.rawValue).tag(bt)
                        }
                    }
                    
                    TextField("Allergies (comma separated)", text: $allergiesRaw)
                    TextField("Conditions (comma separated)", text: $conditionsRaw)
                    
                    TextField("Height (cm)", text: $heightRaw)
                        .keyboardType(.decimalPad)
                    TextField("Weight (kg)", text: $weightRaw)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveProfile()
                        }
                        .disabled(firstName.isEmpty || lastName.isEmpty)
                    }
                }
            }
            .disabled(isSaving)
            .alert("Save Failed", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "An unknown error occurred. Please try again.")
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        
        draftPatient.personalInfo.firstName = firstName
        draftPatient.personalInfo.lastName = lastName
        draftPatient.personalInfo.phone = phone
        draftPatient.personalInfo.address = address
        draftPatient.personalInfo.city = city
        draftPatient.personalInfo.dateOfBirth = dateOfBirth
        draftPatient.personalInfo.gender = gender
        
        draftPatient.medicalInfo.bloodType = bloodType
        draftPatient.medicalInfo.allergies = allergiesRaw.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        draftPatient.medicalInfo.chronicConditions = conditionsRaw.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        if let h = Double(heightRaw) {
            draftPatient.medicalInfo.height = h
        }
        
        if let w = Double(weightRaw) {
            draftPatient.medicalInfo.weight = w
        }
        
        let patientToSave = draftPatient
        
        Task {
            do {
                try await dataStore.savePatientProfileAsync(patientToSave)
                HapticManager.success()
                dismiss()
            } catch {
                saveError = error.localizedDescription
                showError = true
                isSaving = false
                HapticManager.error()
            }
        }
    }
}
