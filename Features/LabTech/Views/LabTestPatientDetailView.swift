//
//  LabTestPatientDetailView.swift
//  MedNex
//
//  Shows all lab tests for a single patient.
//  Lab technicians can update status and enter results directly.

import SwiftUI
import UniformTypeIdentifiers

struct LabTestPatientDetailView: View {
    let patientGroup: PatientLabGroup
    @Environment(DataStore.self) private var dataStore
    @State private var animateCards = false
    
    /// Live tests for this patient (re-computed from DataStore for real-time updates)
    private var tests: [LabTest] {
        dataStore.labTests
            .filter { $0.patientId == patientGroup.patientId && $0.status != .completed && $0.status != .cancelled }
            .sorted { $0.orderedAt > $1.orderedAt }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Patient Header
                VStack(spacing: MedNexTheme.Spacing.sm) {
                    AvatarView(name: patientGroup.patientName, size: 72, backgroundColor: MedNexTheme.Colors.patientTint)
                        .shadow(color: MedNexTheme.Colors.patientTint.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Text(patientGroup.patientName)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    
                    Text("\(tests.count) active test\(tests.count == 1 ? "" : "s")")
                        .font(MedNexTheme.Typography.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, MedNexTheme.Spacing.md)
                .opacity(animateCards ? 1 : 0)
                
                // Test Cards
                if tests.isEmpty {
                    EmptyStateView(icon: "checkmark.circle", title: "All Done!", message: "All tests for this patient have been completed.")
                        .padding(.top, MedNexTheme.Spacing.xl)
                } else {
                    ForEach(tests) { test in
                        LabTestDetailCard(test: test)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 10)
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Patient Tests")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
    }
}

// MARK: - Individual Lab Test Detail Card
struct LabTestDetailCard: View {
    let test: LabTest
    @Environment(DataStore.self) private var dataStore
    @State private var isExpanded = false
    @State private var uploadedReportURL: String?
    @State private var showResultSubmitted = false
    @State private var isImporting = false
    
    private var hasUploadedReport: Bool {
        let storedURL = test.reportPDFURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let localURL = uploadedReportURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !storedURL.isEmpty || !localURL.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — always visible
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
                HapticManager.selection()
            } label: {
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(test.testName)
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                            
                            Text(test.testCategory.rawValue)
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            StatusBadge(text: test.status.displayName, color: statusColor(test.status), icon: test.status.icon)
                            StatusBadge(text: test.priority.displayName, color: Color(hex: test.priority.color))
                        }
                    }
                    
                    HStack(spacing: MedNexTheme.Spacing.md) {
                        Label(test.orderedAt.shortDate, systemImage: "calendar")
                        if !test.doctorName.isEmpty {
                            Label(test.doctorName, systemImage: "stethoscope")
                        }
                    }
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                    
                    HStack {
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        Text(isExpanded ? "Collapse" : "Tap to update")
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(MedNexTheme.Colors.primary)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(MedNexTheme.Spacing.md)
            
            // Expandable Content
            if isExpanded {
                Divider().padding(.horizontal, MedNexTheme.Spacing.md)
                
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                    // Notes
                    if !test.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            Text(test.notes)
                                .font(MedNexTheme.Typography.body)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                    }
                    
                    // Status Update Buttons
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                        Text("ACTIONS")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        
                        HStack(spacing: MedNexTheme.Spacing.sm) {
                                Button {
                                    HapticManager.medium()
                                    isImporting = true
                                } label: {
                                    Label(hasUploadedReport ? "Uploaded" : "Upload", systemImage: hasUploadedReport ? "checkmark.circle.fill" : "square.and.arrow.up")
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(hasUploadedReport ? MedNexTheme.Colors.success : MedNexTheme.Colors.primary)

                                Button {
                                    HapticManager.medium()
                                    let reportURL = test.reportPDFURL ?? uploadedReportURL
                                    dataStore.updateLabTestStatus(test.id, status: .completed, reportPDFURL: reportURL)
                                    HapticManager.success()
                                    showResultSubmitted = true
                                } label: {
                                    Label("Mark as Done", systemImage: "checkmark.circle.fill")
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(MedNexTheme.Colors.success)
                                .disabled(!hasUploadedReport)
                        }
                    }
                }
                .padding(MedNexTheme.Spacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg))
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .image, .text],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    let fakeUploadedURL = "uploaded://\(url.lastPathComponent)-\(Int(Date().timeIntervalSince1970))"
                    uploadedReportURL = fakeUploadedURL
                    dataStore.updateLabTestStatus(test.id, status: .processing, reportPDFURL: fakeUploadedURL)
                    HapticManager.success()
                }
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
        .alert("Results Submitted!", isPresented: $showResultSubmitted) {
            Button("OK") {}
        } message: {
            Text("The test results have been saved and will appear in the patient's medical records.")
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
