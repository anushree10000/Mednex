//
//  DoctorLabOrderView.swift
//  MedNex
//
//  Doctor can order lab tests and review completed results.

import SwiftUI

struct DoctorLabOrderView: View {
    let appState: AppState
    @State private var selectedSegment = 0
    @State private var showOrderSheet = false
    @State private var animateCards = false
    @Environment(DataStore.self) private var dataStore
    
    private var pendingTests: [LabTest] {
        dataStore.labTests.filter { $0.status != .completed }
    }
    
    private var completedTests: [LabTest] {
        dataStore.labTests.filter { $0.status == .completed }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                    StatCard(title: "Ordered", value: "\(dataStore.labTests.count)", icon: "flask.fill", tintColor: MedNexTheme.Colors.info)
                    StatCard(title: "Pending", value: "\(pendingTests.count)", icon: "clock.fill", tintColor: MedNexTheme.Colors.warning)
                    StatCard(title: "Completed", value: "\(completedTests.count)", icon: "checkmark.circle.fill", tintColor: MedNexTheme.Colors.success)
                    StatCard(title: "Urgent", value: "\(dataStore.labTests.filter { $0.priority == .urgent || $0.priority == .stat }.count)", icon: "exclamationmark.triangle.fill", tintColor: MedNexTheme.Colors.error)
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 15)
                
                // Segment
                Picker("Filter", selection: $selectedSegment) {
                    Text("Pending").tag(0)
                    Text("Completed").tag(1)
                }
                .pickerStyle(.segmented)
                
                if selectedSegment == 0 {
                    if pendingTests.isEmpty {
                        EmptyStateView(icon: "flask", title: "No Pending Tests", message: "All ordered tests have been completed.")
                            .padding(.top, MedNexTheme.Spacing.xxl)
                    } else {
                        ForEach(pendingTests) { test in
                            labTestCard(test)
                        }
                    }
                } else {
                    if completedTests.isEmpty {
                        EmptyStateView(icon: "doc.text", title: "No Results Yet", message: "Completed test results will appear here.")
                            .padding(.top, MedNexTheme.Spacing.xxl)
                    } else {
                        ForEach(completedTests) { test in
                            labResultCard(test)
                        }
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .scrollContentBackground(.hidden)
        .refreshable { await dataStore.refreshFromBackend() }
        .doctorFlowBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showOrderSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showOrderSheet) {
            NavigationStack {
                NewLabOrderSheet(appState: appState)
            }
        }
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
    }
    
    // MARK: - Lab Test Card
    private func labTestCard(_ test: LabTest) -> some View {
        DoctorCard(cornerRadius: MedNexTheme.CornerRadius.lg, padding: MedNexTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(test.testName)
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        Text(test.patientName)
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: MedNexTheme.Spacing.xxs) {
                        StatusBadge(text: test.status.displayName, color: statusColor(test.status), icon: test.status.icon)
                        StatusBadge(text: test.priority.displayName, color: Color(hex: test.priority.color))
                    }
                }
                
                HStack(spacing: MedNexTheme.Spacing.lg) {
                    Label(test.orderedAt.shortDate, systemImage: "calendar")
                    Label(test.testCategory.rawValue, systemImage: "tag")
                }
                .font(.system(.caption2, weight: .medium))
                .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
        }
    }
    
    // MARK: - Lab Result Card
    private func labResultCard(_ test: LabTest) -> some View {
        DoctorCard(cornerRadius: MedNexTheme.CornerRadius.lg, padding: MedNexTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(test.testName)
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        Text(test.patientName)
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    Spacer()
                    StatusBadge(text: "Completed", color: MedNexTheme.Colors.success, icon: "checkmark.circle.fill")
                }
                
                if !test.results.isEmpty {
                    Divider().overlay(MedNexTheme.Colors.separator)
                    
                    ForEach(test.results) { result in
                        HStack {
                            Text(result.parameterName)
                                .font(.system(.caption, weight: .medium))
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            Spacer()
                            Text(result.value)
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(result.isAbnormal ? MedNexTheme.Colors.error : MedNexTheme.Colors.textPrimary)
                            Text(result.unit)
                                .font(.system(.caption2, weight: .regular))
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        }
                    }
                    
                    Text("Normal range: \(test.results.first?.normalRange ?? "—")")
                        .font(.system(.caption2, weight: .regular))
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
                
                if let completedAt = test.completedAt {
                    HStack(spacing: MedNexTheme.Spacing.xs) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Completed: \(completedAt.medicalFormat)")
                    }
                    .font(.system(.caption2, weight: .regular))
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
            }
        }
    }
    
    private func statusColor(_ status: LabTestStatus) -> Color {
        switch status {
        case .completed: return MedNexTheme.Colors.success
        case .pending: return MedNexTheme.Colors.warning
        case .processing: return MedNexTheme.Colors.info
        case .received: return MedNexTheme.Colors.primary
        case .cancelled: return MedNexTheme.Colors.error
        }
    }
}

// MARK: - New Lab Order Sheet
struct NewLabOrderSheet: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @State private var selectedPatientId = ""
    @State private var selectedTest = ""
    @State private var selectedCategory: LabTestCategory = .bloodWork
    @State private var selectedPriority: LabTestPriority = .routine
    @State private var notes = ""
    @State private var showNotesWritingTools = false
    @State private var showOrdered = false
    
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
    
    private let testNames = ["Complete Blood Count (CBC)", "Lipid Profile", "Liver Function Test", "Kidney Function Test", "Thyroid Panel", "HbA1c", "Urine Analysis", "Chest X-Ray", "ECG"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Patient
                DoctorCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        Label("Patient", systemImage: "person.fill")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        Menu {
                            ForEach(patients, id: \.id) { p in
                                Button(p.name) { selectedPatientId = p.id }
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
                            .background(MedNexTheme.Colors.elevatedBackground, in: Capsule())
                        }
                    }
                }
                
                // Test Selection
                DoctorCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        Label("Test", systemImage: "flask.fill")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        Menu {
                            ForEach(testNames, id: \.self) { t in
                                Button(t) { selectedTest = t }
                            }
                        } label: {
                            HStack {
                                Text(selectedTest.isEmpty ? "Select test..." : selectedTest)
                                    .foregroundStyle(selectedTest.isEmpty ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                            .padding(MedNexTheme.Spacing.sm)
                            .background(MedNexTheme.Colors.elevatedBackground, in: Capsule())
                        }
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(LabTestCategory.allCases, id: \.self) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(MedNexTheme.Colors.primary)
                    }
                }
                
                // Priority
                DoctorCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        Label("Priority", systemImage: "flag.fill")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        Picker("Priority", selection: $selectedPriority) {
                            ForEach(LabTestPriority.allCases, id: \.self) { p in
                                Text(p.displayName).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                // Notes
                DoctorCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        HStack {
                            Label("Notes", systemImage: "note.text")
                                .font(MedNexTheme.Typography.headline)
                                .foregroundStyle(MedNexTheme.Colors.primary)
                            Spacer()
                            WritingToolsButton(isPresented: $showNotesWritingTools)
                            DictationButton(text: $notes)
                        }
                        
                        RichTextEditor(text: $notes, showWritingTools: $showNotesWritingTools)
                            .frame(minHeight: 80, maxHeight: 150)
                            .padding(MedNexTheme.Spacing.md)
                            .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md))
                    }
                }
                
                Button {
                    HapticManager.success()
                    _ = dataStore.orderLabTest(
                        patientId: selectedPatientId,
                        patientName: selectedPatientName,
                        doctorId: appState.currentUser?.id ?? "",
                        doctorName: appState.currentUser?.displayName ?? "Doctor",
                        testName: selectedTest,
                        testCategory: selectedCategory,
                        priority: selectedPriority,
                        notes: notes
                    )
                    showOrdered = true
                } label: {
                    Text("Order Lab Test")
                }
                .buttonStyle(.medNexPrimary)
                .disabled(selectedTest.isEmpty || selectedPatientId.isEmpty)
                .opacity(selectedTest.isEmpty || selectedPatientId.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .doctorFlowBackground()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .alert("Lab Test Ordered!", isPresented: $showOrdered) {
            Button("Done") { dismiss() }
        } message: {
            Text("\(selectedTest) has been ordered for \(selectedPatientName).")
        }
    }
}
