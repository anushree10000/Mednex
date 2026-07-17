//
//  PatientLabOrdersView.swift
//  MedNex
//
//  Full lab test history view with Active / Completed tabs.
//  Shows test status, details, and PDF download for completed tests.

import SwiftUI

struct PatientLabOrdersView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var selectedTab = 0
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var animateCards = false
    
    private var activeTests: [LabTest] {
        dataStore.labTests
            .filter { $0.status == .pending || $0.status == .processing || $0.status == .received }
            .sorted { $0.orderedAt > $1.orderedAt }
    }
    
    private var completedTests: [LabTest] {
        dataStore.labTests
            .filter { $0.status == .completed || $0.status == .cancelled }
            .sorted { ($0.completedAt ?? $0.orderedAt) > ($1.completedAt ?? $1.orderedAt) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Lab Tests", selection: $selectedTab) {
                Text("Active").tag(0)
                Text("Completed").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.vertical, MedNexTheme.Spacing.sm)
            
            ScrollView {
                LazyVStack(spacing: MedNexTheme.Spacing.md) {
                    if selectedTab == 0 {
                        if activeTests.isEmpty {
                            EmptyStateView(icon: "flask", title: "No Active Tests", message: "You don't have any pending lab tests.")
                        } else {
                            ForEach(activeTests) { test in
                                labTestCard(test, showActions: false)
                            }
                        }
                    } else {
                        if completedTests.isEmpty {
                            EmptyStateView(icon: "checkmark.circle", title: "No Completed Tests", message: "Your completed lab test results will appear here.")
                        } else {
                            ForEach(completedTests) { test in
                                labTestCard(test, showActions: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
        }
        .navigationTitle("Lab Tests")
        .scrollContentBackground(.hidden)
        .refreshable { await dataStore.refreshFromBackend() }
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ActivityView(activityItems: [url])
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    // MARK: - Lab Test Card
    private func labTestCard(_ test: LabTest, showActions: Bool) -> some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            // Header
            HStack {
                HStack(spacing: MedNexTheme.Spacing.sm) {
                    Image(systemName: categoryIcon(test.testCategory))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(categoryColor(test.testCategory))
                        .frame(width: 36, height: 36)
                        .background(categoryColor(test.testCategory).opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(test.testName)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        Text(test.testCategory.rawValue)
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                }
                Spacer()
                StatusBadge(text: test.status.displayName, color: statusColor(test.status), icon: test.status.icon)
            }
            
            // Meta Info
            HStack(spacing: MedNexTheme.Spacing.md) {
                Label(test.orderedAt.shortDate, systemImage: "calendar")
                if !test.doctorName.isEmpty && test.doctorName != "Self-Requested" {
                    Label(test.doctorName, systemImage: "stethoscope")
                } else {
                    Label("Self-Requested", systemImage: "person.fill")
                }
            }
            .font(MedNexTheme.Typography.caption)
            .foregroundStyle(MedNexTheme.Colors.textTertiary)
            
            // Priority
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: test.priority.color))
                    .frame(width: 8, height: 8)
                Text("\(test.priority.displayName) Priority")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
            }
            
            // Results (for completed tests)
            if test.status == .completed && !test.results.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Results")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    
                    ForEach(test.results.prefix(3)) { result in
                        HStack {
                            Text(result.parameterName)
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            Spacer()
                            Text("\(result.value) \(result.unit)")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(result.isAbnormal ? .red : MedNexTheme.Colors.textPrimary)
                            Text("(\(result.normalRange))")
                                .font(MedNexTheme.Typography.caption2)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        }
                    }
                    if test.results.count > 3 {
                        Text("+ \(test.results.count - 3) more parameters")
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                    }
                }
            }
            
            // Actions
            if showActions && test.status == .completed {
                Divider()
                HStack(spacing: MedNexTheme.Spacing.sm) {
                    Button {
                        HapticManager.success()
                        generatePDF(for: test)
                    } label: {
                        Label("Download PDF", systemImage: "arrow.down.doc.fill")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(MedNexTheme.Colors.primary)
                    
                    Button {
                        HapticManager.success()
                        generatePDF(for: test)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(MedNexTheme.Colors.info)
                }
            }
        }
        .padding(MedNexTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg)
                .fill(MedNexTheme.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 10)
    }
    
    // MARK: - Helpers
    private func statusColor(_ status: LabTestStatus) -> Color {
        switch status {
        case .completed: return MedNexTheme.Colors.success
        case .pending: return MedNexTheme.Colors.warning
        case .processing: return MedNexTheme.Colors.info
        case .received: return MedNexTheme.Colors.primary
        case .cancelled: return MedNexTheme.Colors.error
        }
    }
    
    private func categoryIcon(_ category: LabTestCategory) -> String {
        switch category {
        case .bloodWork: return "drop.fill"
        case .urinalysis: return "flask.fill"
        case .imaging: return "xray"
        case .biopsy: return "scissors"
        case .cardiology: return "heart.fill"
        case .microbiology: return "allergens"
        case .hormonal: return "waveform.path.ecg"
        case .genetic: return "dna"
        case .other: return "testtube.2"
        }
    }
    
    private func categoryColor(_ category: LabTestCategory) -> Color {
        switch category {
        case .bloodWork: return .red
        case .urinalysis: return .orange
        case .imaging: return MedNexTheme.Colors.info
        case .biopsy: return .purple
        case .cardiology: return .pink
        case .microbiology: return .green
        case .hormonal: return MedNexTheme.Colors.warning
        case .genetic: return MedNexTheme.Colors.primary
        case .other: return MedNexTheme.Colors.textSecondary
        }
    }
    
    private func generatePDF(for test: LabTest) {
        let pdfData = MedicalRecordPDFGenerator.generateLabReportPDF(
            for: test,
            patient: dataStore.patient
        )
        let fileName = "MedNex_LabReport_\(test.id.prefix(6)).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: tempURL)
            pdfURL = tempURL
            showShareSheet = true
        } catch {
            print("Failed to write PDF: \(error)")
        }
    }
}
