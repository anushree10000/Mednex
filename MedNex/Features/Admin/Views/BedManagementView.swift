//
//  BedManagementView.swift
//  MedNex
//
//  Admin can track bed allocation, admissions, discharges, transfers,
//  and bed history. Nurse controls cleaning → available transitions.
//  Admin retains maintenance toggle and overall oversight.

import SwiftUI

struct BedManagementView: View {
    @State private var selectedWard = 0
    @State private var selectedFloor = 0
    @State private var showAssign = false
    @State private var showDischarge = false
    @State private var showTransfer = false
    @State private var selectedBed: BedInfo? = nil
    @State private var animateCards = false
    @Environment(DataStore.self) private var dataStore
    
    private let wards = ["All Wards", "General Ward", "ICU", "Pediatrics", "Maternity", "Private Rooms"]
    private let floors = ["All Floors", "Ground Floor", "1st Floor", "2nd Floor", "3rd Floor"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Capacity Alert
                if occupancyRate > 0.85 {
                    capacityAlert
                }
                
                // Summary Stats
                summaryStats
                
                // Occupancy Rate Card
                occupancyCard
                
                // Filters
                filterSection
                
                // Bed Grid
                bedGrid
                
                // Bed History Log
                bedHistoryLog
                
                // Legend
                legendCard
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Bed Management")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
        .alert("Assign Patient", isPresented: $showAssign) {
            Button("Reserve Bed") {
                HapticManager.success()
                dataStore.addNotification(
                    title: "Bed Reserved",
                    message: "Bed \(selectedBed?.number ?? "") has been reserved for incoming admission.",
                    type: .general
                )
            }
            Button("Admit Now") {
                HapticManager.success()
                dataStore.addNotification(
                    title: "Patient Admitted",
                    message: "Patient admitted to bed \(selectedBed?.number ?? ""). Status updated to occupied.",
                    type: .general
                )
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Assign a patient to bed \(selectedBed?.number ?? "")?\n\nReserve: hold for incoming admission\nAdmit Now: immediately mark as occupied")
        }
        .alert("Discharge Patient", isPresented: $showDischarge) {
            Button("Confirm Discharge", role: .destructive) {
                if let bed = selectedBed {
                    HapticManager.success()
                    dataStore.addNotification(
                        title: "Patient Discharged",
                        message: "Bed \(bed.number) — \(bed.patientName ?? "Patient") discharged. Bed sent for cleaning.",
                        type: .general
                    )
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Discharge patient from bed \(selectedBed?.number ?? "")?\n\nBed status will change to 'Cleaning' and the assigned nurse will be notified to prepare the bed.")
        }
        .alert("Transfer Patient", isPresented: $showTransfer) {
            Button("Transfer") {
                HapticManager.success()
                dataStore.addNotification(
                    title: "Patient Transfer",
                    message: "Transfer initiated from bed \(selectedBed?.number ?? ""). Select destination on next screen.",
                    type: .general
                )
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Transfer patient from bed \(selectedBed?.number ?? "") to another bed?\n\nSelect the destination ward and bed on the next screen.")
        }
    }
    
    // MARK: - Capacity Alert Banner
    private var capacityAlert: some View {
        GlassCard(padding: MedNexTheme.Spacing.sm) {
            HStack(spacing: MedNexTheme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(MedNexTheme.Colors.error)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("High Occupancy Alert")
                        .font(MedNexTheme.Typography.subheadline.weight(.semibold))
                        .foregroundStyle(MedNexTheme.Colors.error)
                    Text("Bed occupancy is at \(Int(occupancyRate * 100))%. Consider activating overflow protocol or diverting non-urgent admissions.")
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md)
                .stroke(MedNexTheme.Colors.error.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - Summary Stats
    private var summaryStats: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: MedNexTheme.Spacing.sm) {
            StatCard(title: "Total", value: "\(allBeds.count)", icon: "bed.double.fill", tintColor: MedNexTheme.Colors.info)
            StatCard(title: "Available", value: "\(allBeds.filter { $0.status == .available }.count)", icon: "checkmark.circle.fill", tintColor: MedNexTheme.Colors.success)
            StatCard(title: "Occupied", value: "\(allBeds.filter { $0.status == .occupied }.count)", icon: "person.fill", tintColor: MedNexTheme.Colors.warning)
            StatCard(title: "Reserved", value: "\(allBeds.filter { $0.status == .reserved }.count)", icon: "clock.fill", tintColor: MedNexTheme.Colors.info)
            StatCard(title: "Cleaning", value: "\(allBeds.filter { $0.status == .cleaning }.count)", icon: "sparkles", tintColor: Color(hex: "8B5CF6"))
            StatCard(title: "Maintenance", value: "\(allBeds.filter { $0.status == .maintenance }.count)", icon: "wrench.fill", tintColor: MedNexTheme.Colors.error)
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 15)
    }
    
    // MARK: - Occupancy Rate
    private var occupancyCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                Label("Occupancy Rate", systemImage: "chart.bar.fill")
                    .font(MedNexTheme.Typography.headline)
                    .foregroundStyle(MedNexTheme.Colors.primary)
                
                let occupied = allBeds.filter { $0.status == .occupied }.count
                let rate = occupancyRate
                
                HStack {
                    Text("\(Int(rate * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(rate > 0.85 ? MedNexTheme.Colors.error : rate > 0.7 ? MedNexTheme.Colors.warning : MedNexTheme.Colors.success)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(occupied)/\(allBeds.count) beds")
                            .font(MedNexTheme.Typography.subheadline)
                        Text("currently occupied")
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                    }
                }
                
                ProgressView(value: rate)
                    .tint(rate > 0.85 ? MedNexTheme.Colors.error : rate > 0.7 ? MedNexTheme.Colors.warning : MedNexTheme.Colors.success)
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }
    
    // MARK: - Filters
    private var filterSection: some View {
        VStack(spacing: MedNexTheme.Spacing.xs) {
            Picker("Ward", selection: $selectedWard) {
                ForEach(wards.indices, id: \.self) { i in
                    Text(wards[i]).tag(i)
                }
            }
            .pickerStyle(.segmented)
            
            Picker("Floor", selection: $selectedFloor) {
                ForEach(floors.indices, id: \.self) { i in
                    Text(floors[i]).tag(i)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Bed Grid
    private var bedGrid: some View {
        let filtered = filteredBeds
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MedNexTheme.Spacing.sm), count: 3), spacing: MedNexTheme.Spacing.sm) {
            ForEach(filtered) { bed in
                Button {
                    selectedBed = bed
                    HapticManager.light()
                    switch bed.status {
                    case .available: showAssign = true
                    case .occupied: showDischarge = true
                    case .reserved: showAssign = true
                    default: break
                    }
                } label: {
                    VStack(spacing: MedNexTheme.Spacing.xs) {
                        Image(systemName: bed.status.icon)
                            .font(.title2)
                            .foregroundStyle(bedStatusColor(bed.status))
                        
                        Text(bed.number)
                            .font(MedNexTheme.Typography.caption.weight(.semibold))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        
                        Text(bed.status.displayName)
                            .font(MedNexTheme.Typography.caption2)
                            .foregroundStyle(bedStatusColor(bed.status))
                        
                        if let patient = bed.patientName {
                            Text(patient)
                                .font(MedNexTheme.Typography.caption2)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                .lineLimit(1)
                        }
                        
                        if bed.status == .occupied {
                            HStack(spacing: 2) {
                                Button {
                                    selectedBed = bed
                                    showTransfer = true
                                } label: {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.caption2)
                                        .foregroundStyle(MedNexTheme.Colors.info)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(MedNexTheme.Spacing.sm)
                    .background(
                        bedStatusColor(bed.status).opacity(0.08),
                        in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md)
                            .stroke(bedStatusColor(bed.status).opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 25)
    }
    
    // MARK: - Bed History Log
    private var bedHistoryLog: some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            SectionHeader(title: "Recent Bed Activity")
            
            ForEach(bedHistoryEntries, id: \.id) { entry in
                GlassCard(padding: MedNexTheme.Spacing.sm) {
                    HStack(spacing: MedNexTheme.Spacing.sm) {
                        Image(systemName: entry.icon)
                            .foregroundStyle(entry.color)
                            .frame(width: 28, height: 28)
                            .background(entry.color.opacity(0.12), in: Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.action)
                                .font(MedNexTheme.Typography.subheadline.weight(.medium))
                            Text(entry.detail)
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(entry.time)
                            .font(MedNexTheme.Typography.caption2)
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                    }
                }
            }
        }
    }
    
    // MARK: - Legend
    private var legendCard: some View {
        GlassCard(padding: MedNexTheme.Spacing.sm) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                legendItem(color: MedNexTheme.Colors.success, label: "Available")
                legendItem(color: MedNexTheme.Colors.warning, label: "Occupied")
                legendItem(color: MedNexTheme.Colors.info, label: "Reserved")
                legendItem(color: Color(hex: "8B5CF6"), label: "Cleaning")
                legendItem(color: MedNexTheme.Colors.error, label: "Maintenance")
            }
        }
    }
    
    // MARK: - Helpers
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(MedNexTheme.Typography.caption2).foregroundStyle(MedNexTheme.Colors.textSecondary)
        }
    }
    
    private func bedStatusColor(_ status: BedMgmtStatus) -> Color {
        switch status {
        case .available: return MedNexTheme.Colors.success
        case .occupied: return MedNexTheme.Colors.warning
        case .reserved: return MedNexTheme.Colors.info
        case .cleaning: return Color(hex: "8B5CF6")
        case .maintenance: return MedNexTheme.Colors.error
        }
    }
    
    private var occupancyRate: Double {
        let occupied = allBeds.filter { $0.status == .occupied }.count
        return Double(occupied) / Double(max(allBeds.count, 1))
    }
    
    private var filteredBeds: [BedInfo] {
        var result = allBeds
        if selectedWard > 0 {
            result = result.filter { $0.ward == wards[selectedWard] }
        }
        if selectedFloor > 0 {
            result = result.filter { $0.floor == floors[selectedFloor] }
        }
        return result
    }
    
    // MARK: - Data
    private var allBeds: [BedInfo] {
        dataStore.beds.map { bed in
            let mappedStatus: BedMgmtStatus
            switch bed.status {
            case .available: mappedStatus = .available
            case .occupied: mappedStatus = .occupied
            case .reserved: mappedStatus = .reserved
            case .cleaning: mappedStatus = .cleaning
            case .maintenance: mappedStatus = .maintenance
            }
            return BedInfo(
                id: bed.id,
                number: bed.bedNumber,
                ward: bed.ward,
                floor: bed.floor,
                status: mappedStatus,
                patientName: bed.patientName
            )
        }
    }
    
    private var bedHistoryEntries: [BedHistoryEntry] {
        // Generate from recent bed-related notifications
        dataStore.notifications
            .filter { $0.title.localizedCaseInsensitiveContains("Bed") || $0.title.localizedCaseInsensitiveContains("Discharg") || $0.title.localizedCaseInsensitiveContains("Admit") || $0.title.localizedCaseInsensitiveContains("Transfer") }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(5)
            .map { notif in
                let icon: String
                let color: Color
                if notif.title.contains("Admit") {
                    icon = "person.fill.checkmark"; color = MedNexTheme.Colors.success
                } else if notif.title.contains("Discharg") {
                    icon = "arrow.right.circle.fill"; color = MedNexTheme.Colors.warning
                } else if notif.title.contains("Clean") || notif.title.contains("Ready") {
                    icon = "sparkles"; color = Color(hex: "8B5CF6")
                } else if notif.title.contains("Transfer") {
                    icon = "arrow.left.arrow.right"; color = MedNexTheme.Colors.info
                } else {
                    icon = "bed.double.fill"; color = MedNexTheme.Colors.info
                }
                return BedHistoryEntry(action: notif.title, detail: notif.body, icon: icon, color: color, time: notif.createdAt.relative)
            }
    }
}

// MARK: - Models
struct BedInfo: Identifiable {
    let id: String
    let number: String
    let ward: String
    let floor: String
    let status: BedMgmtStatus
    let patientName: String?
}

enum BedMgmtStatus {
    case available, occupied, reserved, cleaning, maintenance
    
    var displayName: String {
        switch self {
        case .available: return "Available"
        case .occupied: return "Occupied"
        case .reserved: return "Reserved"
        case .cleaning: return "Cleaning"
        case .maintenance: return "Maintenance"
        }
    }
    
    var icon: String {
        switch self {
        case .available: return "bed.double"
        case .occupied: return "bed.double.fill"
        case .reserved: return "clock.fill"
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench.fill"
        }
    }
}

struct BedHistoryEntry: Identifiable {
    let id = UUID()
    let action: String
    let detail: String
    let icon: String
    let color: Color
    let time: String
}
