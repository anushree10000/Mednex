//
//  LabTechTabView.swift
//  MedNex
//
//  Rewritten: Queue tab groups tests by patient, tappable cards,
//  Completed tab replaces Results tab, real-time updates.

import SwiftUI

struct LabTechTabView: View {
    let appState: AppState
    @State private var selectedTab = 0
    @State private var showProfile = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Queue", systemImage: "flask.fill", value: 0) {
                NavigationStack {
                    LabQueueView(appState: appState, showProfile: $showProfile)
                        .toolbar { profileToolbarItem() }
                }
            }
            
            Tab("Completed", systemImage: "checkmark.circle.fill", value: 1) {
                NavigationStack {
                    LabCompletedView()
                        .toolbar { profileToolbarItem() }
                }
            }
        }
        .tint(MedNexTheme.Colors.primary)
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                StaffProfileView(appState: appState)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button { showProfile = false } label: {
                                Image(systemName: "xmark")
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                        }
                    }
            }
        }
    }

    @ToolbarContentBuilder
    private func profileToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                HapticManager.selection()
                showProfile = true
            } label: {
                AvatarView(
                    name: appState.currentUser?.displayName ?? "L",
                    imageURL: appState.currentUser?.profileImageURL,
                    size: 32,
                    backgroundColor: MedNexTheme.Colors.labTechTint
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
    }
}

// MARK: - Lab Queue (Grouped by Patient)
struct LabQueueView: View {
    let appState: AppState
    @Binding var showProfile: Bool
    @State private var animateCards = false
    @State private var selectedPatientGroup: PatientLabGroup?
    @Environment(DataStore.self) private var dataStore
    
    private var activeTests: [LabTest] {
        dataStore.labTests.filter { $0.status != .completed && $0.status != .cancelled }
    }
    
    /// Group tests by patient into a single card per patient
    private var patientGroups: [PatientLabGroup] {
        let grouped = Dictionary(grouping: activeTests, by: \.patientId)
        return grouped.map { (patientId, tests) in
            let sortedTests = tests.sorted { $0.orderedAt > $1.orderedAt }
            let patientName = sortedTests.first?.patientName ?? "Unknown"
            return PatientLabGroup(
                patientId: patientId,
                patientName: patientName,
                tests: sortedTests
            )
        }.sorted { $0.tests.first?.orderedAt ?? Date() > $1.tests.first?.orderedAt ?? Date() }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Patient-grouped cards
                if patientGroups.isEmpty {
                    EmptyStateView(icon: "flask", title: "No Active Tests", message: "All lab tests have been completed. New requests will appear here in real-time.")
                        .padding(.top, MedNexTheme.Spacing.xl)
                } else {
                    ForEach(patientGroups) { group in
                        Button {
                            HapticManager.selection()
                            selectedPatientGroup = group
                        } label: {
                            patientGroupCard(group)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Lab Queue")
        .refreshable { await dataStore.refreshFromBackend() }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
        .navigationDestination(item: $selectedPatientGroup) { group in
            LabTestPatientDetailView(patientGroup: group)
        }
    }
    
    private func patientGroupCard(_ group: PatientLabGroup) -> some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            // Patient Header
            HStack(spacing: MedNexTheme.Spacing.sm) {
                    AvatarView(name: group.patientName, size: 44, backgroundColor: MedNexTheme.Colors.patientTint)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.patientName)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        Text("\(group.tests.count) test\(group.tests.count == 1 ? "" : "s")")
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Priority indicator
                    if group.tests.contains(where: { $0.priority == .stat || $0.priority == .urgent }) {
                        let highestPriority = group.tests.contains(where: { $0.priority == .stat }) ? LabTestPriority.stat : .urgent
                        StatusBadge(text: highestPriority.displayName, color: Color(hex: highestPriority.color))
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
                
                // Test Summary
                ForEach(group.tests.prefix(3)) { test in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: MedNexTheme.Spacing.sm) {
                            Image(systemName: test.status.icon)
                                .font(.system(size: 12))
                                .foregroundStyle(labStatusColor(test.status))
                                .frame(width: 20)
                            
                            Text(test.testName)
                                .font(MedNexTheme.Typography.subheadline)
                                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            StatusBadge(text: test.status.displayName, color: labStatusColor(test.status))
                        }
                        
                        if test.status == .pending {
                            Button {
                                HapticManager.selection()
                                // Let the parent view or a DataStore handle the update
                                Task {
                                    // Move to processing
                                    dataStore.updateLabTestStatus(test.id, status: .processing, reportPDFURL: nil)
                                }
                            } label: {
                                Text("Move to Processing")
                                    .font(.system(.caption, design: .rounded, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(MedNexTheme.Colors.primary)
                            .padding(.top, 4)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                
                if group.tests.count > 3 {
                    Text("+ \(group.tests.count - 3) more tests")
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
                
                // Ordered date
                if let latestDate = group.tests.first?.orderedAt {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Latest: \(latestDate.shortDate)")
                    }
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
            }
        .padding(MedNexTheme.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg))
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 10)
    }
    
    private func labStatusColor(_ status: LabTestStatus) -> Color {
        switch status {
        case .completed: return MedNexTheme.Colors.success
        case .pending: return MedNexTheme.Colors.warning
        case .processing: return MedNexTheme.Colors.info
        case .received: return MedNexTheme.Colors.primary
        case .cancelled: return MedNexTheme.Colors.error
        }
    }
}

// MARK: - Completed Lab Tests Tab
struct LabCompletedView: View {
    @State private var animateCards = false
    @Environment(DataStore.self) private var dataStore
    
    private var completedTests: [LabTest] {
        dataStore.labTests
            .filter { $0.status == .completed }
    }
    
    private var patientGroups: [PatientLabGroup] {
        let grouped = Dictionary(grouping: completedTests, by: \.patientId)
        return grouped.map { (patientId, tests) in
            let sortedTests = tests.sorted { ($0.completedAt ?? $0.orderedAt) > ($1.completedAt ?? $1.orderedAt) }
            let patientName = sortedTests.first?.patientName ?? "Unknown"
            return PatientLabGroup(
                patientId: patientId,
                patientName: patientName,
                tests: sortedTests
            )
        }.sorted { ($0.tests.first?.completedAt ?? $0.tests.first?.orderedAt ?? Date()) > ($1.tests.first?.completedAt ?? $1.tests.first?.orderedAt ?? Date()) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                if patientGroups.isEmpty {
                    EmptyStateView(icon: "checkmark.circle", title: "No Completed Tests", message: "Completed lab tests will appear here.")
                        .padding(.top, MedNexTheme.Spacing.xxl)
                } else {
                    LazyVStack(spacing: MedNexTheme.Spacing.xl) {
                        ForEach(patientGroups) { group in
                            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                                HStack(spacing: MedNexTheme.Spacing.sm) {
                                    AvatarView(name: group.patientName, size: 36, backgroundColor: MedNexTheme.Colors.patientTint)
                                    Text(group.patientName)
                                        .font(.system(.title3, design: .rounded, weight: .bold))
                                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                    Spacer()
                                    Text("\(group.tests.count) tests")
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                }
                                .padding(.horizontal, 4)
                                
                                VStack(spacing: MedNexTheme.Spacing.sm) {
                                    ForEach(group.tests) { test in
                                        completedTestCard(test)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                    .padding(.bottom, MedNexTheme.Spacing.xxl)
                }
            }
        }
        .navigationTitle("Completed")
        .refreshable { await dataStore.refreshFromBackend() }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
    }
    
    private func completedTestCard(_ test: LabTest) -> some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                        Text(test.testName)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    }
                    Spacer()
                    StatusBadge(text: "Completed", color: MedNexTheme.Colors.success, icon: "checkmark.circle.fill")
                }
                
                HStack(spacing: MedNexTheme.Spacing.md) {
                    Label(test.testCategory.rawValue, systemImage: "tag")
                    Label((test.completedAt ?? test.orderedAt).shortDate, systemImage: "calendar")
                }
                .font(MedNexTheme.Typography.caption)
                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                
                if !test.results.isEmpty {
                    Divider()
                    Text("\(test.results.count) parameters • \(test.results.filter { $0.isAbnormal }.count) abnormal")
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(test.results.contains(where: { $0.isAbnormal }) ? .red : MedNexTheme.Colors.textSecondary)
                }
            }
        
        .padding(MedNexTheme.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg))
    }
}

// MARK: - Patient Lab Group Model
struct PatientLabGroup: Identifiable, Hashable {
    let patientId: String
    let patientName: String
    let tests: [LabTest]
    
    var id: String { patientId }
}
