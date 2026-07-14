//
//  AdminDoctorPerformanceView.swift
//  MedNex
//
//  H0-43: Doctor performance metrics — all computed from real backend data.
//  No dummy/mock values. Every metric is derived from DataStore appointments,
//  prescriptions, and doctor records fetched from Supabase.

import SwiftUI
import Charts

struct AdminDoctorPerformanceView: View {
    let dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var timeRange: PerformanceTimeRange = .last30Days
    @State private var sortBy: PerformanceSortKey = .completionRate
    @State private var selectedDoctor: DoctorPerformanceRow?
    
    // MARK: - Computed Metrics
    
    private var doctorMetrics: [DoctorPerformanceRow] {
        let threshold = timeRange.threshold
        
        return dataStore.doctors.map { doctor in
            let doctorId = doctor.userId.isEmpty ? doctor.id : doctor.userId
            
            let appointments = dataStore.appointments.filter {
                $0.doctorId == doctorId && $0.dateTime >= threshold
            }
            
            let total = appointments.count
            let completed = appointments.filter { $0.status == .completed }.count
            let cancelled = appointments.filter { $0.status == .cancelled }.count
            let noShow = appointments.filter { $0.status == .noShow }.count
            
            let ratings = appointments.compactMap { $0.rating }
            let avgRating = ratings.isEmpty ? nil : Double(ratings.reduce(0, +)) / Double(ratings.count)
            
            let rxCount = dataStore.prescriptions.filter {
                $0.doctorId == doctorId && $0.createdAt >= threshold
            }.count
            
            let completionRate = total > 0 ? Double(completed) / Double(total) * 100 : 0
            let cancellationRate = total > 0 ? Double(cancelled) / Double(total) * 100 : 0
            let noShowRate = total > 0 ? Double(noShow) / Double(total) * 100 : 0
            
            return DoctorPerformanceRow(
                doctor: doctor,
                totalAppointments: total,
                completedAppointments: completed,
                cancelledAppointments: cancelled,
                noShowCount: noShow,
                completionRate: completionRate,
                cancellationRate: cancellationRate,
                noShowRate: noShowRate,
                avgRating: avgRating,
                prescriptionsWritten: rxCount
            )
        }
        .sorted { lhs, rhs in
            switch sortBy {
            case .completionRate: return lhs.completionRate > rhs.completionRate
            case .totalAppointments: return lhs.totalAppointments > rhs.totalAppointments
            case .avgRating:
                return (lhs.avgRating ?? 0) > (rhs.avgRating ?? 0)
            case .prescriptions: return lhs.prescriptionsWritten > rhs.prescriptionsWritten
            }
        }
    }
    
    // MARK: - Summary
    
    private var totalAppointments: Int { doctorMetrics.reduce(0) { $0 + $1.totalAppointments } }
    private var avgCompletionRate: Double {
        let activeDocMetrics = doctorMetrics.filter { $0.totalAppointments > 0 }
        guard !activeDocMetrics.isEmpty else { return 0 }
        return activeDocMetrics.reduce(0) { $0 + $1.completionRate } / Double(activeDocMetrics.count)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                summarySection
                chartSection
                doctorListSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Doctor Performance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedDoctor) { row in
                DoctorPerformanceDetailSheet(row: row)
            }
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        Section {
            HStack(spacing: MedNexTheme.Spacing.md) {
                summaryPill(
                    title: "Appointments",
                    value: "\(totalAppointments)",
                    icon: "calendar.badge.checkmark",
                    tint: MedNexTheme.Colors.primary
                )
                summaryPill(
                    title: "Avg Completion",
                    value: "\(Int(avgCompletionRate))%",
                    icon: "chart.line.uptrend.xyaxis",
                    tint: MedNexTheme.Colors.success
                )
                summaryPill(
                    title: "Doctors",
                    value: "\(dataStore.doctors.count)",
                    icon: "stethoscope",
                    tint: MedNexTheme.Colors.info
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            // Controls
            HStack {
                Picker("Range", selection: $timeRange) {
                    ForEach(PerformanceTimeRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Picker("Sort by", selection: $sortBy) {
                ForEach(PerformanceSortKey.allCases) { key in
                    Text(key.label).tag(key)
                }
            }
        }
    }
    
    private func summaryPill(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MedNexTheme.Spacing.sm)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md))
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        Section("Completion Rate by Doctor") {
            let chartData = doctorMetrics
                .filter { $0.totalAppointments > 0 }
                .prefix(8)
            
            if chartData.isEmpty {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "chart.bar.xaxis",
                    description: Text("No appointments in the selected time range.")
                )
            } else {
                Chart(Array(chartData)) { row in
                    BarMark(
                        x: .value("Rate", row.completionRate),
                        y: .value("Doctor", row.doctor.name)
                    )
                    .foregroundStyle(barColor(for: row.completionRate))
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text("\(Int(row.completionRate))%")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                }
                .chartXScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))%")
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                    }
                }
                .frame(height: CGFloat(chartData.count) * 44 + 20)
            }
        }
    }
    
    private func barColor(for rate: Double) -> Color {
        if rate >= 80 { return MedNexTheme.Colors.success }
        if rate >= 50 { return MedNexTheme.Colors.warning }
        return MedNexTheme.Colors.error
    }
    
    // MARK: - Doctor List
    
    private var doctorListSection: some View {
        Section("All Doctors") {
            if doctorMetrics.isEmpty {
                ContentUnavailableView(
                    "No Doctors",
                    systemImage: "person.3",
                    description: Text("No doctors found in the system.")
                )
            } else {
                ForEach(doctorMetrics) { row in
                    Button { selectedDoctor = row } label: {
                        doctorPerformanceRow(row)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func doctorPerformanceRow(_ row: DoctorPerformanceRow) -> some View {
        HStack(spacing: MedNexTheme.Spacing.sm) {
            AvatarView(
                name: row.doctor.name,
                imageURL: row.doctor.profileImageURL,
                size: 40,
                backgroundColor: MedNexTheme.Colors.primary
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(row.doctor.name)
                    .font(.subheadline.weight(.medium))
                Text(row.doctor.specialty.rawValue)
                    .font(.caption)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(Int(row.completionRate))%")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(barColor(for: row.completionRate))
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(barColor(for: row.completionRate))
                }
                Text("\(row.totalAppointments) appts")
                    .font(.caption2)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.doctor.name), \(row.doctor.specialty.rawValue), \(Int(row.completionRate)) percent completion rate, \(row.totalAppointments) appointments")
    }
}

// MARK: - Detail Sheet

private struct DoctorPerformanceDetailSheet: View {
    let row: DoctorPerformanceRow
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: MedNexTheme.Spacing.md) {
                        AvatarView(
                            name: row.doctor.name,
                            imageURL: row.doctor.profileImageURL,
                            size: 56,
                            backgroundColor: MedNexTheme.Colors.primary
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.doctor.name)
                                .font(.headline)
                            Text(row.doctor.specialty.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            if row.doctor.experience > 0 {
                                Text("\(row.doctor.experience) years experience")
                                    .font(.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section("Appointments") {
                    metricRow("Total", value: "\(row.totalAppointments)", icon: "calendar", tint: MedNexTheme.Colors.info)
                    metricRow("Completed", value: "\(row.completedAppointments)", icon: "checkmark.circle.fill", tint: MedNexTheme.Colors.success)
                    metricRow("Cancelled", value: "\(row.cancelledAppointments)", icon: "xmark.circle.fill", tint: MedNexTheme.Colors.error)
                    metricRow("No-Shows", value: "\(row.noShowCount)", icon: "person.fill.xmark", tint: MedNexTheme.Colors.warning)
                }
                
                Section("Rates") {
                    metricRow("Completion Rate", value: "\(Int(row.completionRate))%", icon: "chart.line.uptrend.xyaxis", tint: MedNexTheme.Colors.success)
                    metricRow("Cancellation Rate", value: "\(Int(row.cancellationRate))%", icon: "chart.line.downtrend.xyaxis", tint: MedNexTheme.Colors.error)
                    metricRow("No-Show Rate", value: "\(Int(row.noShowRate))%", icon: "exclamationmark.triangle.fill", tint: MedNexTheme.Colors.warning)
                }
                
                Section("Other") {
                    if let avg = row.avgRating {
                        metricRow("Avg Rating", value: String(format: "%.1f ★", avg), icon: "star.fill", tint: .orange)
                    } else {
                        metricRow("Avg Rating", value: "No ratings", icon: "star", tint: MedNexTheme.Colors.textTertiary)
                    }
                    metricRow("Prescriptions", value: "\(row.prescriptionsWritten)", icon: "doc.text.fill", tint: MedNexTheme.Colors.primary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Performance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func metricRow(_ title: String, value: String, icon: String, tint: Color) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Supporting Types

struct DoctorPerformanceRow: Identifiable {
    let doctor: Doctor
    let totalAppointments: Int
    let completedAppointments: Int
    let cancelledAppointments: Int
    let noShowCount: Int
    let completionRate: Double
    let cancellationRate: Double
    let noShowRate: Double
    let avgRating: Double?
    let prescriptionsWritten: Int
    
    var id: String { doctor.id }
}

enum PerformanceTimeRange: String, CaseIterable, Identifiable {
    case last7Days
    case last30Days
    case last90Days
    case allTime
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .last7Days: return "7D"
        case .last30Days: return "30D"
        case .last90Days: return "90D"
        case .allTime: return "All"
        }
    }
    
    var threshold: Date {
        switch self {
        case .last7Days: return Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        case .last30Days: return Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        case .last90Days: return Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? .distantPast
        case .allTime: return .distantPast
        }
    }
}

enum PerformanceSortKey: String, CaseIterable, Identifiable {
    case completionRate
    case totalAppointments
    case avgRating
    case prescriptions
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .completionRate: return "Completion Rate"
        case .totalAppointments: return "Total Appointments"
        case .avgRating: return "Rating"
        case .prescriptions: return "Prescriptions"
        }
    }
}
