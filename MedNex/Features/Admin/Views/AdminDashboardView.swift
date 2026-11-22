//
//  AdminDashboardView.swift
//  MedNex
//

import SwiftUI
import Charts

struct AdminDashboardView: View {
    let appState: AppState
    @Binding var showProfile: Bool
    @State private var animateCards = false
    @Environment(DataStore.self) private var dataStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Welcome
                HStack {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                        Text("Admin Panel")
                            .font(MedNexTheme.Typography.title2)
                        Text(appState.currentUser?.displayName ?? "Administrator")
                            .font(MedNexTheme.Typography.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Button { showProfile = true } label: {
                        AvatarView(name: appState.currentUser?.displayName ?? "A", size: 52, backgroundColor: MedNexTheme.Colors.adminTint)
                    }
                }
                .opacity(animateCards ? 1 : 0)
                
                // Key Metrics
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                    StatCard(title: "Total Staff", value: "\(dataStore.staff.count + dataStore.doctors.count)", icon: "person.3.fill", trend: .up, trendValue: "+2", tintColor: MedNexTheme.Colors.primary)
                    StatCard(title: "Departments", value: "\(dataStore.departments.count)", icon: "building.2.fill", tintColor: MedNexTheme.Colors.info)
                    StatCard(title: "Revenue", value: "₹\(totalRevenue / 1000)K", icon: "indianrupeesign.circle.fill", trend: .up, trendValue: "+8%", tintColor: MedNexTheme.Colors.success)
                    StatCard(title: "Appointments", value: "\(dataStore.appointments.count)", icon: "calendar", tintColor: MedNexTheme.Colors.warning)
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 15)
                
                // Revenue Chart
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        Label("Revenue Trend (Last 7 Days)", systemImage: "chart.line.uptrend.xyaxis")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        Chart(revenueData, id: \.day) { item in
                            BarMark(x: .value("Day", item.day), y: .value("Amount", item.amount))
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
                .padding(.horizontal, 0)
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 20)
                
                // Department Overview
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                    SectionHeader(title: "Departments")
                    
                    ForEach(dataStore.departments) { dept in
                        GlassCard(padding: MedNexTheme.Spacing.sm) {
                            HStack(spacing: MedNexTheme.Spacing.sm) {
                                Image(systemName: "building.2.fill")
                                    .foregroundStyle(MedNexTheme.Colors.primary)
                                    .frame(width: 36, height: 36)
                                    .background(MedNexTheme.Colors.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(dept.name)
                                        .font(MedNexTheme.Typography.subheadline.weight(.medium))
                                    Text("Head: \(dept.headDoctorName ?? "N/A")")
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("\(dept.staffCount)")
                                        .font(MedNexTheme.Typography.headline)
                                        .foregroundStyle(MedNexTheme.Colors.primary)
                                    Text("staff")
                                        .font(MedNexTheme.Typography.caption2)
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                }
                            }
                        }
                    }
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 25)
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Dashboard")
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) {
                animateCards = true
            }
        }
    }
    
    private var totalRevenue: Int {
        Int(dataStore.totalRevenue)
    }
    
    private var revenueData: [(day: String, amount: Double)] {
        let calendar = Calendar.current
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var revenueByDay: [String: Double] = [:]
        for bill in dataStore.bills {
            let weekday = calendar.component(.weekday, from: bill.createdAt) // 1=Sun..7=Sat
            let dayName = dayNames[weekday - 1]
            revenueByDay[dayName, default: 0] += bill.totalAmount
        }
        return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map { day in
            (day: day, amount: revenueByDay[day] ?? 0)
        }
    }
}
