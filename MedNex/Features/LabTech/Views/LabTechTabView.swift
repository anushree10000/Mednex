//
//  LabTechTabView.swift
//  MedNex
//

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
                }
            }
            
            Tab("Results", systemImage: "doc.text.fill", value: 1) {
                NavigationStack {
                    LabResultEntryView()
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
}

// MARK: - Lab Queue
struct LabQueueView: View {
    let appState: AppState
    @Binding var showProfile: Bool
    @State private var animateCards = false
    @State private var selectedFilter: FilterTag? = nil
    @Environment(DataStore.self) private var dataStore
    
    private var labTests: [LabTest] { dataStore.labTests }
    
    enum FilterTag {
        case pending
        case completed
    }
    
    private var filteredTests: [LabTest] {
        switch selectedFilter {
        case .pending:
            return labTests.filter { $0.status == .pending || $0.status == .processing }
        case .completed:
            return labTests.filter { $0.status == .completed }
        case nil:
            return labTests
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Lab Queue")
                            .font(MedNexTheme.Typography.title2)
                        Text("\(labTests.filter { $0.status != .completed }.count) pending tests")
                            .font(MedNexTheme.Typography.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Button { showProfile = true } label: {
                        AvatarView(name: appState.currentUser?.displayName ?? "L", size: 48, backgroundColor: MedNexTheme.Colors.labTechTint)
                    }
                }
                .opacity(animateCards ? 1 : 0)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                    Button {
                        withAnimation { 
                            selectedFilter = selectedFilter == .pending ? nil : .pending 
                        }
                    } label: {
                        StatCard(title: "Pending", value: "\(labTests.filter { $0.status == .pending || $0.status == .processing }.count)", icon: "clock.fill", tintColor: MedNexTheme.Colors.warning)
                            .overlay(
                                RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md)
                                    .stroke(selectedFilter == .pending ? MedNexTheme.Colors.warning : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        withAnimation { 
                            selectedFilter = selectedFilter == .completed ? nil : .completed
                        }
                    } label: {
                        StatCard(title: "Completed", value: "\(labTests.filter { $0.status == .completed }.count)", icon: "checkmark.circle.fill", tintColor: MedNexTheme.Colors.success)
                            .overlay(
                                RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md)
                                    .stroke(selectedFilter == .completed ? MedNexTheme.Colors.success : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .opacity(animateCards ? 1 : 0)
                
                ForEach(filteredTests) { test in
                    GlassCard {
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(test.testName).font(MedNexTheme.Typography.headline)
                                    Text(test.patientName)
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: MedNexTheme.Spacing.xxs) {
                                    StatusBadge(text: test.status.displayName, color: labStatusColor(test.status), icon: test.status.icon)
                                    StatusBadge(text: test.priority.displayName, color: Color(hex: test.priority.color))
                                }
                            }
                            
                            HStack {
                                Label(test.orderedAt.shortDate, systemImage: "calendar")
                                Label(test.doctorName, systemImage: "stethoscope")
                            }
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            
                            if test.status == .pending {
                                HStack {
                                    Button {
                                        HapticManager.medium()
                                        dataStore.updateLabTestStatus(test.id, status: .processing)
                                    } label: {
                                        Text("Start Processing")
                                            .font(MedNexTheme.Typography.caption.weight(.semibold))
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(MedNexTheme.Colors.primary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Lab Queue")
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
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

// MARK: - Lab Result Entry
struct LabResultEntryView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var testToResult: LabTest?
    
    private var pendingTests: [LabTest] {
        dataStore.labTests.filter { $0.status == .pending || $0.status == .processing }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.md) {
                if pendingTests.isEmpty {
                    VStack(spacing: MedNexTheme.Spacing.md) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(MedNexTheme.Colors.success)
                        Text("No pending tests for results")
                            .font(MedNexTheme.Typography.headline)
                    }
                    .padding(.top, MedNexTheme.Spacing.xxl)
                } else {
                    ForEach(pendingTests) { test in
                        Button {
                            testToResult = test
                        } label: {
                            GlassCard {
                                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(test.testName)
                                                .font(MedNexTheme.Typography.headline)
                                                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                            Text(test.patientName)
                                                .font(MedNexTheme.Typography.subheadline)
                                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Pending Results")
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .sheet(item: $testToResult) { test in
            NavigationStack {
                EnterResultSheet(test: test)
            }
        }
    }
}

struct EnterResultSheet: View {
    let test: LabTest
    @Environment(DataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var parameters: [(name: String, value: String, unit: String, normalRange: String)] = [
        (name: "", value: "", unit: "", normalRange: ""),
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Info
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        Text("Patient: \(test.patientName)")
                            .font(MedNexTheme.Typography.headline)
                        Text("Test: \(test.testName)")
                            .font(MedNexTheme.Typography.subheadline)
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.top, MedNexTheme.Spacing.md)
                
                // Form
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                        HStack {
                            Text("Parameters")
                                .font(MedNexTheme.Typography.headline)
                            Spacer()
                            Button {
                                parameters.append((name: "", value: "", unit: "", normalRange: ""))
                            } label: {
                                Image(systemName: "plus.circle.fill").foregroundStyle(MedNexTheme.Colors.primary)
                            }
                        }
                        
                        ForEach(parameters.indices, id: \.self) { i in
                            VStack(spacing: MedNexTheme.Spacing.xs) {
                                TextField("Parameter name (e.g. Hemoglobin)", text: Binding(get: { parameters[i].name }, set: { parameters[i].name = $0 }))
                                    .padding(MedNexTheme.Spacing.xs)
                                    .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                HStack {
                                    TextField("Value", text: Binding(get: { parameters[i].value }, set: { parameters[i].value = $0 }))
                                        .keyboardType(.decimalPad)
                                    TextField("Unit", text: Binding(get: { parameters[i].unit }, set: { parameters[i].unit = $0 }))
                                    TextField("Normal", text: Binding(get: { parameters[i].normalRange }, set: { parameters[i].normalRange = $0 }))
                                }
                                .padding(MedNexTheme.Spacing.xs)
                                .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                .font(MedNexTheme.Typography.caption)
                                
                                if i < parameters.count - 1 { Divider() }
                            }
                        }
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                
                Button {
                    HapticManager.success()
                    submitResults()
                    dismiss()
                } label: {
                    Text("Submit Results")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.medNexPrimary)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .disabled(parameters.first?.name.isEmpty ?? true)
                .opacity((parameters.first?.name.isEmpty ?? true) ? 0.6 : 1)
            }
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Enter Results")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
    
    private func submitResults() {
        let results = parameters.compactMap { param -> LabTestResult? in
            guard !param.name.isEmpty else { return nil }
            return LabTestResult(
                parameterName: param.name,
                value: param.value,
                unit: param.unit,
                normalRange: param.normalRange,
                isAbnormal: false
            )
        }
        
        dataStore.updateLabTestStatus(test.id, status: .completed, results: results)
        
        dataStore.addNotification(
            title: "Lab Results Ready",
            message: "Results for \(test.testName) have been submitted.",
            type: .labResultReady
        )
    }
}
