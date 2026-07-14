//
//  MedicalRecordEditorView.swift
//  MedNex
//
//  Doctor can add notes, update diagnosis, save patient records.

import SwiftUI

struct MedicalRecordEditorView: View {
    var initialPatientId: String? = nil
    @State private var selectedPatientId = ""
    @State private var diagnosis = ""
    @State private var clinicalNotes = ""
    @State private var treatmentPlan = ""
    @State private var followUpDays = ""
    @State private var showSaved = false
    @State private var showDiagnosisWritingTools = false
    @State private var showClinicalNotesWritingTools = false
    @State private var showTreatmentPlanWritingTools = false
    @State private var animateCards = false
    @Environment(DataStore.self) private var dataStore
    
    /// Unique patients derived from appointment history
    private var patients: [(id: String, name: String)] {
        let grouped = Dictionary(grouping: dataStore.appointments, by: \.patientId)
        return grouped.compactMap { (patientId, appointments) in
            guard let latest = appointments.sorted(by: { $0.dateTime > $1.dateTime }).first else { return nil }
            return (id: patientId, name: latest.patientName)
        }
        .sorted { $0.name < $1.name }
    }
    
    private var selectedPatientName: String {
        patients.first(where: { $0.id == selectedPatientId })?.name ?? ""
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Patient Selection
                DoctorCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        Label("Patient", systemImage: "person.fill")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        Menu {
                            if initialPatientId == nil {
                                ForEach(patients, id: \.id) { patient in
                                    Button(patient.name) { selectedPatientId = patient.id }
                                }
                            }
                        } label: {
                            HStack {
                                AvatarView(name: selectedPatientName.isEmpty ? "?" : selectedPatientName, size: 36, backgroundColor: MedNexTheme.Colors.patientTint)
                                Text(selectedPatientName.isEmpty ? "Select patient..." : selectedPatientName)
                                    .font(MedNexTheme.Typography.body)
                                    .foregroundStyle(selectedPatientName.isEmpty ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                            .padding(MedNexTheme.Spacing.sm)
                            .background(MedNexTheme.Colors.elevatedBackground, in: Capsule())
                        }
                    }
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 15)
                
                // Diagnosis
                DoctorCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        Label("Diagnosis", systemImage: "stethoscope")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        HStack {
                            RichTextEditor(text: $diagnosis, showWritingTools: $showDiagnosisWritingTools)
                                .padding(.horizontal, MedNexTheme.Spacing.lg)
                                .padding(.vertical, MedNexTheme.Spacing.sm)
                                .frame(height: 52)
                                .background(MedNexTheme.Colors.elevatedBackground, in: Capsule())
                            
                            WritingToolsButton(isPresented: $showDiagnosisWritingTools)
                        }
                    }
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 20)
                
                // Clinical Notes
                DoctorCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        HStack {
                            Label("Clinical Notes", systemImage: "note.text")
                                .font(MedNexTheme.Typography.headline)
                                .foregroundStyle(MedNexTheme.Colors.primary)
                            Spacer()
                            WritingToolsButton(isPresented: $showClinicalNotesWritingTools)
                            DictationButton(text: $clinicalNotes)
                        }
                        
                        RichTextEditor(text: $clinicalNotes, showWritingTools: $showClinicalNotesWritingTools)
                            .frame(minHeight: 100, maxHeight: 200)
                            .padding(MedNexTheme.Spacing.md)
                            .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md))
                    }
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 25)
                
                // Treatment Plan
                DoctorCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        HStack {
                            Label("Treatment Plan", systemImage: "list.clipboard.fill")
                                .font(MedNexTheme.Typography.headline)
                                .foregroundStyle(MedNexTheme.Colors.primary)
                            Spacer()
                            WritingToolsButton(isPresented: $showTreatmentPlanWritingTools)
                            DictationButton(text: $treatmentPlan)
                        }
                        
                        RichTextEditor(text: $treatmentPlan, showWritingTools: $showTreatmentPlanWritingTools)
                            .frame(minHeight: 80, maxHeight: 150)
                            .padding(MedNexTheme.Spacing.md)
                            .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md))
                        
                        HStack {
                            Label("Follow-up in", systemImage: "calendar.badge.clock")
                                .font(MedNexTheme.Typography.subheadline)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            
                            TextField("days", text: $followUpDays, prompt: Text("days").foregroundStyle(MedNexTheme.Colors.textTertiary))
                                .keyboardType(.numberPad)
                                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                .padding(.horizontal, MedNexTheme.Spacing.md)
                                .padding(.vertical, MedNexTheme.Spacing.xs)
                                .frame(width: 80, height: 40)
                                .background(MedNexTheme.Colors.elevatedBackground, in: Capsule())
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 30)
                
                // Save Button
                Button {
                    HapticManager.success()
                    saveMedicalRecord()
                    showSaved = true
                } label: {
                    Text("Save Medical Record")
                }
                .buttonStyle(.medNexPrimary)
                .disabled(diagnosis.isEmpty && clinicalNotes.isEmpty)
                .opacity(diagnosis.isEmpty && clinicalNotes.isEmpty ? 0.5 : 1)
                
                // Past Records
                if !selectedPatientId.isEmpty {
                    let pastAppts = dataStore.appointments.filter { $0.patientId == selectedPatientId && $0.dateTime < Date() }.sorted { $0.dateTime > $1.dateTime }
                    if !pastAppts.isEmpty {
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                            Text("Past Records")
                                .font(MedNexTheme.Typography.title3)
                                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                .padding(.horizontal, MedNexTheme.Spacing.md)
                                .padding(.top, MedNexTheme.Spacing.md)
                            
                            ForEach(pastAppts) { appt in
                                DoctorCard {
                                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                                        Text(appt.type.displayName)
                                            .font(MedNexTheme.Typography.headline)
                                        Text(appt.dateTime.medicalFormat)
                                            .font(MedNexTheme.Typography.caption)
                                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                        
                                        if !appt.notes.isEmpty {
                                            Text(appt.notes)
                                                .font(MedNexTheme.Typography.caption)
                                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                                .padding(.top, 4)
                                        }
                                    }
                                }
                                .padding(.horizontal, MedNexTheme.Spacing.md)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .doctorFlowBackground()
        .onAppear {
            if let initialPatientId {
                selectedPatientId = initialPatientId
            }
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
        .alert("Record Saved!", isPresented: $showSaved) {
            Button("OK") {
                diagnosis = ""
                clinicalNotes = ""
                treatmentPlan = ""
                followUpDays = ""
            }
        } message: {
            Text("Medical record for \(selectedPatientName) has been updated.")
        }
    }
    
    private func saveMedicalRecord() {
        var details = [String]()
        if !diagnosis.isEmpty { details.append("Diagnosis: \(diagnosis)") }
        if !treatmentPlan.isEmpty { details.append("Treatment: \(treatmentPlan)") }
        if !followUpDays.isEmpty { details.append("Follow-up: \(followUpDays) days") }
        
        dataStore.addNotification(
            title: "Medical Record Updated",
            message: "Record for \(selectedPatientName) updated. \(details.joined(separator: ". "))",
            type: .general
        )
    }
}
