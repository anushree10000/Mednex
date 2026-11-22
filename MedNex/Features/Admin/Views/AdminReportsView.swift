//
//  AdminReportsView.swift
//  MedNex
//
//  Hospital admin reporting & analytics dashboard.

import SwiftUI
import Charts

struct AdminReportsView: View {
    @State private var selectedPeriod = 0
    @State private var animateCards = false
    @Environment(DataStore.self) private var dataStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Period selector
                Picker("Period", selection: $selectedPeriod) {
                    Text("Week").tag(0)
                    Text("Month").tag(1)
                    Text("Quarter").tag(2)
                }
                .pickerStyle(.segmented)
                
                // KPI Summary
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                    StatCard(title: "Patient Visits", value: "\(dataStore.appointments.count)", icon: "person.3.fill", tintColor: MedNexTheme.Colors.primary)
                    StatCard(title: "Revenue", value: "₹\(Int(dataStore.bills.reduce(0) { $0 + $1.totalAmount }))", icon: "indianrupeesign.circle.fill", tintColor: MedNexTheme.Colors.success)
                    StatCard(title: "Pending Bills", value: "\(dataStore.bills.filter { $0.status != .paid }.count)", icon: "clock.fill", tintColor: MedNexTheme.Colors.info)
                    StatCard(title: "Completion", value: "\(Int(overallCompletionRate))%", icon: "star.fill", tintColor: MedNexTheme.Colors.warning)
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 15)
                
                // Patient Volume Chart
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        Label("Patient Volume", systemImage: "chart.bar.fill")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        Chart(patientVolumeData, id: \.day) { item in
                            BarMark(x: .value("Day", item.day), y: .value("Count", item.count))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [MedNexTheme.Colors.primary, MedNexTheme.Colors.primary.opacity(0.5)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(4)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { _ in
                                AxisValueLabel().foregroundStyle(MedNexTheme.Colors.textSecondary)
                                AxisGridLine().foregroundStyle(MedNexTheme.Colors.separator)
                            }
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel().foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                        }
                        .frame(height: 180)
                    }
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 20)
                
                // Revenue Breakdown
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        Label("Revenue by Department", systemImage: "chart.pie.fill")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        Chart(departmentRevenue, id: \.name) { item in
                            SectorMark(angle: .value("Revenue", item.revenue), innerRadius: .ratio(0.6), angularInset: 2)
                                .foregroundStyle(item.color)
                                .cornerRadius(4)
                        }
                        .frame(height: 200)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.xs) {
                            ForEach(departmentRevenue, id: \.name) { item in
                                HStack(spacing: MedNexTheme.Spacing.xs) {
                                    Circle().fill(item.color).frame(width: 8, height: 8)
                                    Text(item.name)
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                }
                            }
                        }
                    }
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 25)
                
                // Appointment Completion Rate
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        Label("Appointment Completion", systemImage: "chart.line.uptrend.xyaxis")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        Chart(completionData, id: \.day) { item in
                            LineMark(x: .value("Day", item.day), y: .value("Rate", item.rate))
                                .foregroundStyle(MedNexTheme.Colors.success)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
                            
                            AreaMark(x: .value("Day", item.day), y: .value("Rate", item.rate))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [MedNexTheme.Colors.success.opacity(0.3), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { _ in
                                AxisValueLabel().foregroundStyle(MedNexTheme.Colors.textSecondary)
                                AxisGridLine().foregroundStyle(MedNexTheme.Colors.separator)
                            }
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel().foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                        }
                        .frame(height: 160)
                    }
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 30)
                
                // Top Performing Departments
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                    SectionHeader(title: "Department Performance")
                    
                    ForEach(dataStore.departments) { dept in
                        GlassCard(padding: MedNexTheme.Spacing.sm) {
                            HStack(spacing: MedNexTheme.Spacing.md) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(dept.name)
                                        .font(MedNexTheme.Typography.subheadline.weight(.medium))
                                    Text("\(dept.staffCount) staff")
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                }
                                
                                Spacer()
                                
                                let total = dataStore.appointments.filter { appt in
                                    dataStore.departments.contains(where: { $0.name == dept.name })
                                }.count
                                let completed = dataStore.appointments.filter { $0.status == .completed }.count
                                let efficiency = total > 0 ? Double(completed) / Double(max(total, 1)) * 100 : 85
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(Int(efficiency))%")
                                        .font(MedNexTheme.Typography.headline)
                                        .foregroundStyle(efficiency > 90 ? MedNexTheme.Colors.success : MedNexTheme.Colors.warning)
                                    Text("efficiency")
                                        .font(MedNexTheme.Typography.caption2)
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                }
                            }
                        }
                    }
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 35)
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Reports")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
    }
    
    // MARK: - Data
    private var overallCompletionRate: Double {
        let total = dataStore.appointments.count
        let completed = dataStore.appointments.filter { $0.status == .completed }.count
        return total > 0 ? Double(completed) / Double(total) * 100 : 0
    }
    
    private var patientVolumeData: [(day: String, count: Double)] {
        let calendar = Calendar.current
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var countsByDay: [String: Int] = [:]
        for appt in dataStore.appointments {
            let weekday = calendar.component(.weekday, from: appt.dateTime)
            let dayName = dayNames[weekday - 1]
            countsByDay[dayName, default: 0] += 1
        }
        return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map {
            (day: $0, count: Double(countsByDay[$0] ?? 0))
        }
    }
    
    private var departmentRevenue: [(name: String, revenue: Double, color: Color)] {
        let colors: [Color] = [MedNexTheme.Colors.error, MedNexTheme.Colors.primary, MedNexTheme.Colors.success, MedNexTheme.Colors.info, MedNexTheme.Colors.warning, Color(hex: "8B5CF6")]
        return dataStore.departments.prefix(6).enumerated().map { (index, dept) in
            let deptRevenue = dataStore.bills.reduce(0.0) { $0 + $1.totalAmount } / Double(max(dataStore.departments.count, 1))
            return (name: dept.name, revenue: deptRevenue, color: colors[index % colors.count])
        }
    }
    
    private var completionData: [(day: String, rate: Double)] {
        let calendar = Calendar.current
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var totalByDay: [String: Int] = [:]
        var completedByDay: [String: Int] = [:]
        for appt in dataStore.appointments {
            let weekday = calendar.component(.weekday, from: appt.dateTime)
            let dayName = dayNames[weekday - 1]
            totalByDay[dayName, default: 0] += 1
            if appt.status == .completed {
                completedByDay[dayName, default: 0] += 1
            }
        }
        return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map { day in
            let total = totalByDay[day] ?? 0
            let completed = completedByDay[day] ?? 0
            let rate = total > 0 ? Double(completed) / Double(total) * 100 : 0
            return (day: day, rate: rate)
        }
    }
}
