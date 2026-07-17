//
//  LabResultsView.swift
//  MedNex
//

import SwiftUI

struct LabResultsView: View {
    @State private var selectedFilter: LabTestStatusFilter = .all
    @Environment(DataStore.self) private var dataStore
    
    var filteredTests: [LabTest] {
        switch selectedFilter {
        case .all: return dataStore.labTests
        case .pending: return dataStore.labTests.filter { $0.status != .completed }
        case .completed: return dataStore.labTests.filter { $0.status == .completed }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(LabTestStatusFilter.allCases, id: \.self) { f in Text(f.rawValue.capitalized).tag(f) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.vertical, MedNexTheme.Spacing.sm)
            
            ScrollView {
                LazyVStack(spacing: MedNexTheme.Spacing.sm) {
                    ForEach(filteredTests) { test in
                        GlassCard {
                            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                                HStack {
                                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                                        Text(test.testName)
                                            .font(MedNexTheme.Typography.headline)
                                        Text("Ordered by \(test.doctorName)")
                                            .font(MedNexTheme.Typography.caption)
                                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                        Text(test.orderedAt.shortDate)
                                            .font(MedNexTheme.Typography.caption)
                                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: MedNexTheme.Spacing.xxs) {
                                        StatusBadge(text: test.status.displayName, color: statusColor(test.status), icon: test.status.icon)
                                        StatusBadge(text: test.priority.displayName, color: Color(hex: test.priority.color))
                                    }
                                }
                                
                                // Results (if completed)
                                if test.status == .completed && !test.results.isEmpty {
                                    Divider()
                                    ForEach(test.results) { result in
                                        HStack {
                                            Text(result.parameterName)
                                                .font(MedNexTheme.Typography.subheadline)
                                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                            Spacer()
                                            Text(result.value)
                                                .font(MedNexTheme.Typography.subheadline.weight(.semibold))
                                                .foregroundStyle(result.isAbnormal ? MedNexTheme.Colors.error : MedNexTheme.Colors.textPrimary)
                                            Text(result.unit)
                                                .font(MedNexTheme.Typography.caption)
                                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                        }
                                        
                                        HStack {
                                            Text("Normal: \(result.normalRange)")
                                                .font(MedNexTheme.Typography.caption)
                                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                            Spacer()
                                            if result.isAbnormal {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .foregroundStyle(MedNexTheme.Colors.error)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
        }
        .navigationTitle("Lab Results")
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

enum LabTestStatusFilter: String, CaseIterable {
    case all, pending, completed
}
