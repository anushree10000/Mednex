//
//  PatientLabRequestView.swift
//  MedNex
//
//  Patient can directly request lab tests (doctor referral is optional).

import SwiftUI

struct PatientLabRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @State private var selectedCategory = PatientLabCategory.bloodWork
    @State private var selectedTests: Set<String> = []
    @State private var preferredDate = Date().addingTimeInterval(86400)
    @State private var notes = ""
    @State private var doctorReferral = ""
    @State private var showConfirmation = false
    @State private var animateCards = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Header card
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        Label("Request Lab Test", systemImage: "flask.fill")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        Text("Select your tests below. A doctor referral is optional for routine tests.")
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                }
                .opacity(animateCards ? 1 : 0)
                
                // Category picker
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                    Text("Test Category")
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(PatientLabCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .opacity(animateCards ? 1 : 0)
                
                // Available tests for selected category
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        Text("Select Tests")
                            .font(MedNexTheme.Typography.headline)
                        
                        ForEach(selectedCategory.availableTests, id: \.self) { test in
                            Button {
                                HapticManager.selection()
                                if selectedTests.contains(test) {
                                    selectedTests.remove(test)
                                } else {
                                    selectedTests.insert(test)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: selectedTests.contains(test) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedTests.contains(test) ? MedNexTheme.Colors.primary : MedNexTheme.Colors.textTertiary)
                                        .font(.title3)
                                    
                                    Text(test)
                                        .font(MedNexTheme.Typography.subheadline)
                                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            
                            if test != selectedCategory.availableTests.last {
                                Divider().overlay(MedNexTheme.Colors.textTertiary.opacity(0.2))
                            }
                        }
                    }
                }
                .opacity(animateCards ? 1 : 0)
                
                // Preferred date
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        Label("Preferred Date", systemImage: "calendar")
                            .font(MedNexTheme.Typography.headline)
                        
                        DatePicker("Date", selection: $preferredDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .tint(MedNexTheme.Colors.primary)
                    }
                }
                .opacity(animateCards ? 1 : 0)
                
                // Doctor referral (optional)
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        HStack {
                            Label("Doctor Referral", systemImage: "stethoscope")
                                .font(MedNexTheme.Typography.headline)
                            
                            Text("Optional")
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(MedNexTheme.Colors.elevatedBackground, in: Capsule())
                        }
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            TextField("Doctor's name (if referred)", text: $doctorReferral)
                        }
                        .padding(MedNexTheme.Spacing.sm)
                        .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                    }
                }
                .opacity(animateCards ? 1 : 0)
                
                // Notes
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        Label("Additional Notes", systemImage: "note.text")
                            .font(MedNexTheme.Typography.headline)
                        
                        TextField("Any symptoms or relevant information...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(MedNexTheme.Spacing.sm)
                            .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                    }
                }
                .opacity(animateCards ? 1 : 0)
                
                // Submit
                Button {
                    HapticManager.success()
                    // Persist each selected test to DataStore (syncs to Supabase)
                    let patient = dataStore.patient
                    for testName in selectedTests {
                        _ = dataStore.orderLabTest(
                            patientId: patient.id,
                            patientName: patient.personalInfo.fullName,
                            doctorId: doctorReferral.isEmpty ? "self-request" : UUID().uuidString,
                            doctorName: doctorReferral.isEmpty ? "Self-Requested" : doctorReferral,
                            testName: testName,
                            testCategory: selectedCategory.labTestCategory,
                            notes: notes
                        )
                    }
                    showConfirmation = true
                } label: {
                    Text("Submit Lab Request")
                }
                .buttonStyle(.medNexPrimary)
                .disabled(selectedTests.isEmpty)
                .opacity(selectedTests.isEmpty ? 0.6 : 1)
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Book Lab Test")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
        .alert("Request Submitted!", isPresented: $showConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your lab test request for \(selectedTests.count) test(s) has been submitted. You'll receive a confirmation with your appointment slot.")
        }
    }
}

// MARK: - Lab Test Categories

enum PatientLabCategory: String, CaseIterable, Identifiable {
    case bloodWork, urine, imaging, cardiac, thyroid, diabetes
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .bloodWork: return "Blood"
        case .urine: return "Urine"
        case .imaging: return "Imaging"
        case .cardiac: return "Cardiac"
        case .thyroid: return "Thyroid"
        case .diabetes: return "Diabetes"
        }
    }
    
    var icon: String {
        switch self {
        case .bloodWork: return "drop.fill"
        case .urine: return "flask.fill"
        case .imaging: return "xray"
        case .cardiac: return "heart.fill"
        case .thyroid: return "waveform.path.ecg"
        case .diabetes: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var availableTests: [String] {
        switch self {
        case .bloodWork: return ["Complete Blood Count (CBC)", "Hemoglobin", "Platelet Count", "ESR", "Blood Grouping", "Liver Function Test (LFT)", "Kidney Function Test (KFT)", "Lipid Profile"]
        case .urine: return ["Routine Urine Analysis", "Urine Culture", "24-Hour Urine Protein", "Urine Microalbumin"]
        case .imaging: return ["X-Ray (Chest)", "X-Ray (Limb)", "Ultrasound (Abdomen)", "CT Scan", "MRI"]
        case .cardiac: return ["ECG", "Echocardiogram", "Troponin Test", "BNP Test", "Stress Test"]
        case .thyroid: return ["TSH", "T3", "T4", "Free T3", "Free T4", "Thyroid Antibodies"]
        case .diabetes: return ["Fasting Blood Sugar", "Post-Prandial Blood Sugar", "HbA1c", "Oral Glucose Tolerance Test"]
        }
    }
    
    /// Maps to the model-level `LabTestCategory` used by DataStore
    var labTestCategory: LabTestCategory {
        switch self {
        case .bloodWork: return .bloodWork
        case .urine: return .urinalysis
        case .imaging: return .imaging
        case .cardiac: return .cardiology
        case .thyroid: return .hormonal
        case .diabetes: return .bloodWork
        }
    }
}
