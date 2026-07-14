//
//  PrescriptionWriterView.swift
//  MedNex
//

import SwiftUI

struct PrescriptionWriterView: View {
    let appState: AppState
    var initialPatientId: String? = nil
    @State private var selectedPatientId = ""
    @State private var diagnosis = ""
    @State private var showDiagnosisWritingTools = false
    @State private var showNotesWritingTools = false
    @State private var medicines: [PrescribedMedicine] = [PrescribedMedicine(name: "", dosage: "", frequency: .onceDaily, duration: "", instructions: "")]
    @State private var notes = ""
    @State private var showDrugSearch = false
    @State private var showSuccess = false
    @State private var expandedMedicineIndex: Int? = nil
    @State private var medicineSearchText = ""
    @State private var showMedicineSearchSheet = false
    @Environment(DataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss
    
    // Quick suggestions
    private let commonDiagnoses = [
        "Fever", "Cough", "Headache", "Back Pain", "Diabetes",
        "Hypertension", "Asthma", "Migraine", "Bronchitis", "UTI"
    ]
    
    private let commonMedicines = [
        ("Aspirin", "500mg"), ("Amoxicillin", "500mg"), ("Ibuprofen", "400mg"),
        ("Paracetamol", "500mg"), ("Metformin", "500mg"), ("Lisinopril", "10mg"),
        ("Omeprazole", "20mg"), ("Atorvastatin", "20mg"), ("Ciprofloxacin", "500mg"),
        ("Azithromycin", "500mg"), ("Metoprolol", "50mg"), ("Amlodipine", "5mg"),
        ("Atorvastatin", "20mg"), ("Losartan", "50mg"), ("Cetirizine", "10mg"),
        ("Ranitidine", "150mg"), ("Albuterol", "100mcg"), ("Fluticasone", "44mcg"),
        ("Insulin", "10 units"), ("Glibenclamide", "5mg"), ("Levothyroxine", "50mcg"),
        ("Amitriptyline", "25mg"), ("Sertraline", "50mg"), ("Alprazolam", "0.5mg")
    ]
    
    /// Filtered medicines based on search
    private var filteredMedicines: [(name: String, dosage: String)] {
        if medicineSearchText.isEmpty {
            return commonMedicines
        }
        return commonMedicines.filter { 
            $0.0.localizedCaseInsensitiveContains(medicineSearchText) ||
            $0.1.localizedCaseInsensitiveContains(medicineSearchText)
        }
    }
    
    private let commonFrequencies = MedicineFrequency.allCases.map { $0.rawValue }
    private let commonDurations = ["3 days", "5 days", "7 days", "10 days", "14 days", "30 days"]
    
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
    
    /// Find the current active appointment for the selected patient (prefer scheduled/inProgress)
    private var selectedAppointmentId: String {
        let patientAppts = dataStore.appointments
            .filter { $0.patientId == selectedPatientId }
            .sorted { $0.dateTime > $1.dateTime }
        
        // Prefer an active appointment (scheduled or inProgress)
        if let active = patientAppts.first(where: { $0.status == .scheduled || $0.status == .inProgress }) {
            return active.id
        }
        // Fallback to most recent
        return patientAppts.first?.id ?? ""
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                patientAndDiagnosisSection
                medicinesSection
                if !notes.isEmpty || medicines.count > 1 {
                    notesSection
                }
                submitButton
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
        }
        .alert("Prescription Created!", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("The prescription for \(selectedPatientName) has been generated and sent to the pharmacy.")
        }
        .sheet(isPresented: $showMedicineSearchSheet) {
            medicineSearchSheet
        }
    }
    
    // MARK: - Subviews
    
    private var patientAndDiagnosisSection: some View {
        DoctorCard(cornerRadius: MedNexTheme.CornerRadius.lg, padding: MedNexTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                Text("Patient & Diagnosis")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                
                Menu {
                    if initialPatientId == nil {
                        ForEach(patients, id: \.id) { patient in
                            Button(patient.name) { selectedPatientId = patient.id }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedPatientName.isEmpty ? "Select patient..." : selectedPatientName)
                            .foregroundStyle(selectedPatientName.isEmpty ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    .padding(MedNexTheme.Spacing.sm)
                    .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                }
                
                // Diagnosis Field with Quick Suggestions
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                    HStack {
                        RichTextEditor(text: $diagnosis, showWritingTools: $showDiagnosisWritingTools)
                            .frame(height: 52)
                        WritingToolsButton(isPresented: $showDiagnosisWritingTools)
                        DictationButton(text: $diagnosis)
                    }
                    .padding(MedNexTheme.Spacing.sm)
                    .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                    
                    // Quick Diagnosis Suggestions
                    if diagnosis.isEmpty {
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                            Text("Quick Select")
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.xs) {
                                ForEach(commonDiagnoses.prefix(6), id: \.self) { diag in
                                    Button {
                                        diagnosis = diag
                                        HapticManager.light()
                                    } label: {
                                        Text(diag)
                                            .font(.system(.caption, weight: .medium))
                                            .foregroundStyle(MedNexTheme.Colors.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, MedNexTheme.Spacing.xs)
                                            .background(MedNexTheme.Colors.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, MedNexTheme.Spacing.md)
    }
    
    private var medicinesSection: some View {
        DoctorCard(cornerRadius: MedNexTheme.CornerRadius.lg, padding: MedNexTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                HStack {
                    Text("Medicines")
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    Spacer()
                    HStack(spacing: MedNexTheme.Spacing.sm) {
                        Button {
                            HapticManager.light()
                            showMedicineSearchSheet = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(MedNexTheme.Colors.primary)
                        }
                        
                        Button {
                            HapticManager.light()
                            medicines.append(PrescribedMedicine(name: "", dosage: "", frequency: .onceDaily, duration: "", instructions: ""))
                            expandedMedicineIndex = medicines.count - 1
                        } label: {
                            Text("+ Add")
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(MedNexTheme.Colors.primary)
                        }
                    }
                }
                
                // Quick Medicine Suggestions (if no medicines added yet)
                if medicines.allSatisfy({ $0.name.isEmpty }) {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                        Text("Quick Add")
                            .font(.system(.caption2, weight: .semibold))
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        
                        VStack(spacing: MedNexTheme.Spacing.xs) {
                            ForEach(commonMedicines.prefix(6), id: \.0) { name, dosage in
                                Button {
                                    HapticManager.light()
                                    medicines[0].name = name
                                    medicines[0].dosage = dosage
                                    expandedMedicineIndex = 0
                                } label: {
                                    HStack(spacing: MedNexTheme.Spacing.sm) {
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(name).font(.system(.caption, weight: .semibold)).foregroundStyle(MedNexTheme.Colors.textPrimary)
                                            Text(dosage).font(.system(.caption2, weight: .regular)).foregroundStyle(MedNexTheme.Colors.textSecondary)
                                        }
                                        Spacer()
                                        Text("→").foregroundStyle(MedNexTheme.Colors.primary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(MedNexTheme.Spacing.sm)
                                    .background(MedNexTheme.Colors.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                }
                            }
                        }
                    }
                    .padding(.bottom, MedNexTheme.Spacing.sm)
                }
                
                // Compact Medicine List
                ForEach(medicines.indices, id: \.self) { index in
                    let isExpanded = expandedMedicineIndex == index
                    
                    VStack(alignment: .leading, spacing: 0) {
                        // Collapsed Header
                        Button {
                            HapticManager.light()
                            if isExpanded {
                                expandedMedicineIndex = nil
                            } else {
                                expandedMedicineIndex = index
                            }
                        } label: {
                            HStack(spacing: MedNexTheme.Spacing.sm) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(medicines[index].name.isEmpty ? "Medicine \(index + 1)" : medicines[index].name)
                                        .font(.system(.body, weight: .medium))
                                        .foregroundStyle(medicines[index].name.isEmpty ? MedNexTheme.Colors.textSecondary : MedNexTheme.Colors.textPrimary)
                                    
                                    if !medicines[index].dosage.isEmpty || !medicines[index].duration.isEmpty {
                                        HStack(spacing: MedNexTheme.Spacing.xs) {
                                            if !medicines[index].dosage.isEmpty {
                                                Text(medicines[index].dosage)
                                                    .font(.system(.caption, weight: .regular))
                                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                            }
                                            if !medicines[index].duration.isEmpty {
                                                Text("•")
                                                    .font(.caption)
                                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                                Text(medicines[index].duration)
                                                    .font(.system(.caption, weight: .regular))
                                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                            }
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                HStack(spacing: MedNexTheme.Spacing.sm) {
                                    if medicines.count > 1 {
                                        Button {
                                            HapticManager.light()
                                            medicines.remove(at: index)
                                            if expandedMedicineIndex == index {
                                                expandedMedicineIndex = nil
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(MedNexTheme.Colors.error)
                                        }
                                    }
                                    
                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(MedNexTheme.Spacing.sm)
                        
                        // Expanded Details
                        if isExpanded {
                            Divider().padding(.horizontal, MedNexTheme.Spacing.sm)
                            
                            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                                // Medicine Name
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Name").font(.system(.caption2, weight: .semibold)).foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    TextField("e.g., Aspirin", text: $medicines[index].name)
                                        .font(.system(.body, weight: .regular))
                                        .padding(MedNexTheme.Spacing.sm)
                                        .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                }
                                
                                // Dosage
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dosage").font(.system(.caption2, weight: .semibold)).foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    TextField("e.g., 500mg", text: $medicines[index].dosage)
                                        .font(.system(.body, weight: .regular))
                                        .padding(MedNexTheme.Spacing.sm)
                                        .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                }
                                
                                // Duration Quick Select
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Duration").font(.system(.caption2, weight: .semibold)).foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: MedNexTheme.Spacing.xs) {
                                            ForEach(commonDurations, id: \.self) { duration in
                                                Button {
                                                    medicines[index].duration = duration
                                                    HapticManager.light()
                                                } label: {
                                                    Text(duration)
                                                        .font(.system(.caption, weight: .medium))
                                                        .foregroundStyle(medicines[index].duration == duration ? .white : MedNexTheme.Colors.primary)
                                                        .padding(.horizontal, MedNexTheme.Spacing.sm)
                                                        .padding(.vertical, 6)
                                                        .background(medicines[index].duration == duration ? MedNexTheme.Colors.primary : MedNexTheme.Colors.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Frequency Quick Select
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Frequency").font(.system(.caption2, weight: .semibold)).foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.xs) {
                                        ForEach(commonFrequencies, id: \.self) { freq in
                                            Button {
                                                if let mfreq = MedicineFrequency(rawValue: freq) {
                                                    medicines[index].frequency = mfreq
                                                    HapticManager.light()
                                                }
                                            } label: {
                                                Text(freq)
                                                    .font(.system(.caption, weight: .medium))
                                                    .foregroundStyle(medicines[index].frequency.rawValue == freq ? .white : MedNexTheme.Colors.primary)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 6)
                                                    .background(medicines[index].frequency.rawValue == freq ? MedNexTheme.Colors.primary : MedNexTheme.Colors.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                            }
                                        }
                                    }
                                }
                                
                                // Special Instructions (Optional)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Instructions (Optional)").font(.system(.caption2, weight: .semibold)).foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    TextField("e.g., With food", text: $medicines[index].instructions, axis: .vertical)
                                        .lineLimit(1...3)
                                        .font(.system(.caption, weight: .regular))
                                        .padding(MedNexTheme.Spacing.sm)
                                        .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                        .writingToolsBehavior(.complete)
                                }
                            }
                            .padding(MedNexTheme.Spacing.sm)
                        }
                    }
                    .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                    
                    if index < medicines.count - 1 {
                        Divider().padding(.vertical, MedNexTheme.Spacing.xs)
                    }
                }
            }
        }
        .padding(.horizontal, MedNexTheme.Spacing.md)
    }
    
    private var notesSection: some View {
        DoctorCard(cornerRadius: MedNexTheme.CornerRadius.lg, padding: MedNexTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                Text("Additional Notes")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                
                ZStack(alignment: .bottomTrailing) {
                    RichTextEditor(text: $notes, showWritingTools: $showNotesWritingTools)
                        .frame(minHeight: 80, maxHeight: 150)
                        .padding(MedNexTheme.Spacing.sm)
                        .padding(.bottom, MedNexTheme.Spacing.xxl)
                        .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                    
                    HStack(spacing: MedNexTheme.Spacing.sm) {
                        WritingToolsButton(isPresented: $showNotesWritingTools)
                        DictationButton(text: $notes)
                    }
                    .padding(MedNexTheme.Spacing.sm)
                }
            }
        }
        .padding(.horizontal, MedNexTheme.Spacing.md)
    }
    
    private var submitButton: some View {
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
    
    private var medicineSearchSheet: some View {
        NavigationStack {
            List(filteredMedicines, id: \.0) { name, dosage in
                Button {
                    HapticManager.light()
                    if medicines[0].name.isEmpty {
                        medicines[0].name = name
                        medicines[0].dosage = dosage
                        expandedMedicineIndex = 0
                    } else {
                        medicines.append(PrescribedMedicine(name: name, dosage: dosage, frequency: .onceDaily, duration: "", instructions: ""))
                        expandedMedicineIndex = medicines.count - 1
                    }
                    showMedicineSearchSheet = false
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        Text(dosage)
                            .font(.system(.caption, weight: .regular))
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                }
            }
            .searchable(text: $medicineSearchText, prompt: "Search medicines...")
            .navigationTitle("Select Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showMedicineSearchSheet = false
                    }
                }
            }
        }
    }
}
