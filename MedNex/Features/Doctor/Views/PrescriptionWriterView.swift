//
//  PrescriptionWriterView.swift
//  MedNex
//

import SwiftUI

struct PrescriptionWriterView: View {
    let appState: AppState
    @State private var selectedPatientId = ""
    @State private var diagnosis = ""
    @State private var medicines: [PrescribedMedicine] = [PrescribedMedicine(name: "", dosage: "", frequency: .onceDaily, duration: "", instructions: "")]
    @State private var notes = ""
    @State private var showDrugSearch = false
    @State private var showSuccess = false
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
    
    /// Find the most recent appointmentId for the selected patient
    private var selectedAppointmentId: String {
        dataStore.appointments
            .filter { $0.patientId == selectedPatientId }
            .sorted { $0.dateTime > $1.dateTime }
            .first?.id ?? ""
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Patient & Diagnosis
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        Label("Patient & Diagnosis", systemImage: "person.fill")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        Menu {
                            ForEach(patients, id: \.id) { patient in
                                Button(patient.name) { selectedPatientId = patient.id }
                            }
                        } label: {
                            HStack {
                                Text(selectedPatientName.isEmpty ? "Select patient..." : selectedPatientName)
                                    .foregroundStyle(selectedPatientName.isEmpty ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                            .padding(MedNexTheme.Spacing.sm)
                            .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                        }
                        
                        TextField("Diagnosis", text: $diagnosis)
                            .padding(MedNexTheme.Spacing.sm)
                            .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                
                // Medicines
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        HStack {
                            Label("Medicines", systemImage: "pills.fill")
                                .font(MedNexTheme.Typography.headline)
                                .foregroundStyle(MedNexTheme.Colors.primary)
                            Spacer()
                            Button {
                                HapticManager.light()
                                medicines.append(PrescribedMedicine(name: "", dosage: "", frequency: .onceDaily, duration: "", instructions: ""))
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(MedNexTheme.Colors.primary)
                            }
                        }
                        
                        ForEach(medicines.indices, id: \.self) { index in
                            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                                HStack {
                                    Text("Medicine \(index + 1)")
                                        .font(MedNexTheme.Typography.caption.weight(.semibold))
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    Spacer()
                                    if medicines.count > 1 {
                                        Button {
                                            HapticManager.light()
                                            medicines.remove(at: index)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundStyle(MedNexTheme.Colors.error)
                                                .font(.caption)
                                        }
                                    }
                                }
                                
                                TextField("Medicine name", text: $medicines[index].name)
                                    .padding(MedNexTheme.Spacing.xs)
                                    .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                
                                HStack {
                                    TextField("Dosage", text: $medicines[index].dosage)
                                        .padding(MedNexTheme.Spacing.xs)
                                        .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                    
                                    TextField("Duration", text: $medicines[index].duration)
                                        .padding(MedNexTheme.Spacing.xs)
                                        .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                }
                                
                                Picker("Frequency", selection: $medicines[index].frequency) {
                                    ForEach(MedicineFrequency.allCases, id: \.self) { freq in
                                        Text(freq.rawValue).tag(freq)
                                    }
                                }
                                .pickerStyle(.menu)
                                
                                TextField("Special instructions", text: $medicines[index].instructions)
                                    .font(MedNexTheme.Typography.caption)
                                    .padding(MedNexTheme.Spacing.xs)
                                    .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                
                                if index < medicines.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                
                // Notes
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        Label("Additional Notes", systemImage: "note.text")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 80, maxHeight: 150)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                            .padding(MedNexTheme.Spacing.sm)
                            .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                            .writingToolsBehavior(.complete)
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                
                // Submit
                Button {
                    HapticManager.success()
                    let rxMedicines = medicines.map { med in
                        PrescribedMedicine(
                            id: UUID().uuidString,
                            name: med.name,
                            dosage: med.dosage,
                            frequency: med.frequency,
                            duration: med.duration,
                            instructions: med.instructions
                        )
                    }
                    _ = dataStore.createPrescription(
                        appointmentId: selectedAppointmentId,
                        patientId: selectedPatientId,
                        patientName: selectedPatientName,
                        doctorId: appState.currentUser?.id ?? "",
                        doctorName: appState.currentUser?.displayName ?? "Doctor",
                        medicines: rxMedicines,
                        diagnosis: diagnosis,
                        notes: notes
                    )
                    showSuccess = true
                } label: {
                    Text("Generate Prescription")
                }
                .buttonStyle(.medNexPrimary)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .disabled(selectedPatientId.isEmpty || diagnosis.isEmpty)
                .opacity(selectedPatientId.isEmpty || diagnosis.isEmpty ? 0.6 : 1)
            }
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Write Prescription")
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .alert("Prescription Created!", isPresented: $showSuccess) {
            Button("OK") {}
        } message: {
            Text("The prescription for \(selectedPatientName) has been generated and sent to the pharmacy.")
        }
    }
}
