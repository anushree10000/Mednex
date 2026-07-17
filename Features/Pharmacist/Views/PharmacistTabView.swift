//
//  PharmacistTabView.swift
//  MedNex
//

import SwiftUI

struct PharmacistTabView: View {
    let appState: AppState
    @State private var selectedTab = 0
    @State private var showProfile = false
    
    var body: some View {
        TabView(selection: $selectedTab) {

            Tab("Orders", systemImage: "pills.fill", value: 0) {
                NavigationStack {
                    PrescriptionQueueView(appState: appState, showProfile: $showProfile)
                        .toolbar { profileToolbarItem() }
                }
            }

            Tab("Inventory", systemImage: "shippingbox.fill", value: 1) {
                NavigationStack {
                    InventoryView()
                        .toolbar { profileToolbarItem() }
                }
            }

            // NEW TAB
            Tab("Requests", systemImage: "tray.full.fill", value: 2) {
                NavigationStack {
                    RequestInventoryView()
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
                    name: appState.currentUser?.displayName ?? "P",
                    imageURL: appState.currentUser?.profileImageURL,
                    size: 32,
                    backgroundColor: MedNexTheme.Colors.pharmacistTint
                )
            }
            .accessibilityLabel("Profile")
        }
    }
}

// MARK: - Prescription Queue
struct PrescriptionQueueView: View {
    let appState: AppState
    @Binding var showProfile: Bool
    @State private var animateCards = false
    @Environment(DataStore.self) private var dataStore
    
    private var prescriptions: [Prescription] { dataStore.prescriptions }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Pharmacy Queue")
                            .font(MedNexTheme.Typography.title2)
                        Text("\(prescriptions.count) prescriptions")
                            .font(MedNexTheme.Typography.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    Spacer()
                }
                .opacity(animateCards ? 1 : 0)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                    StatCard(title: "To Dispense", value: "\(prescriptions.filter { $0.status == .active }.count)", icon: "pills.fill", tintColor: MedNexTheme.Colors.warning)
                    StatCard(title: "Dispensed", value: "\(prescriptions.filter { $0.status == .completed }.count)", icon: "checkmark.circle.fill", tintColor: MedNexTheme.Colors.success)
                }
                .opacity(animateCards ? 1 : 0)
                
                ForEach(prescriptions) { rx in
                    GlassCard {
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rx.patientName).font(MedNexTheme.Typography.headline)
                                    Text(rx.diagnosis)
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                }
                                Spacer()
                                StatusBadge(text: rx.status.displayName, color: rx.status == .active ? MedNexTheme.Colors.warning : MedNexTheme.Colors.success)
                            }
                            
                            Divider()
                            
                            ForEach(rx.medicines) { med in
                                HStack {
                                    Image(systemName: "pills.fill")
                                        .foregroundStyle(MedNexTheme.Colors.primary)
                                        .font(.caption)
                                    Text("\(med.name) — \(med.dosage) × \(med.frequency.rawValue)")
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    Spacer()
                                    Text(med.duration)
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                }
                            }
                            
                            if rx.status == .active {
                                Button {
                                    HapticManager.success()
                                    dataStore.updatePrescriptionStatus(id: rx.id, status: .completed)
                                } label: {
                                    Text("Mark as Dispensed")
                                        .font(MedNexTheme.Typography.caption.weight(.semibold))
                                }
                                .buttonStyle(.bordered)
                                .tint(MedNexTheme.Colors.success)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Pharmacy")
        .refreshable { await dataStore.refreshFromBackend() }
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
    }
}

// MARK: - Inventory View
struct InventoryView: View {
    @State private var searchText = ""
    @Environment(DataStore.self) private var dataStore
    
    var filteredInventory: [InventoryItem] {
        if searchText.isEmpty { return dataStore.inventory }
        return dataStore.inventory.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.md) {
                MedNexSearchBar(text: $searchText, placeholder: "Search inventory...")
                
                // Low stock alert
                let lowStock = dataStore.lowStockItems
                if !lowStock.isEmpty {
                    GlassCard(padding: MedNexTheme.Spacing.sm) {
                        HStack(spacing: MedNexTheme.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(MedNexTheme.Colors.warning)
                            Text("\(lowStock.count) items are low on stock")
                                .font(MedNexTheme.Typography.subheadline)
                                .foregroundStyle(MedNexTheme.Colors.warning)
                            Spacer()
                        }
                    }
                }
                
                ForEach(filteredInventory) { item in
                    GlassCard(padding: MedNexTheme.Spacing.sm) {
                        HStack(spacing: MedNexTheme.Spacing.md) {
                            Image(systemName: categoryIcon(item.category))
                                .foregroundStyle(MedNexTheme.Colors.primary)
                                .frame(width: 36, height: 36)
                                .background(MedNexTheme.Colors.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(MedNexTheme.Typography.subheadline.weight(.medium))
                                HStack(spacing: MedNexTheme.Spacing.sm) {
                                    Text(item.category.rawValue)
                                    Text("•")
                                    Text(item.supplier)
                                }
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(item.stock)")
                                    .font(MedNexTheme.Typography.headline)
                                    .foregroundStyle(item.isLowStock ? MedNexTheme.Colors.error : MedNexTheme.Colors.success)
                                Text("in stock")
                                    .font(MedNexTheme.Typography.caption2)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Inventory")
        .scrollContentBackground(.hidden)
        .refreshable { await dataStore.refreshFromBackend() }
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
    }
    
    private func categoryIcon(_ cat: InventoryCategory) -> String {
        switch cat {
        case .medication: return "pills.fill"
        case .equipment: return "wrench.and.screwdriver.fill"
        case .consumables: return "bandage.fill"
        case .labSupplies: return "flask.fill"
        case .surgical: return "scissors"
        case .other: return "shippingbox.fill"
        }
    }
}
