//
//  HealthDashboardView.swift
//  MedNex
//

import SwiftUI
import Charts

struct HealthDashboardView: View {
    @State private var selectedPeriod: TimePeriod = .week
    @State private var animateCharts = false
    @Environment(DataStore.self) private var dataStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Period Picker
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                
                // Heart Rate Chart
                chartCard(title: "Heart Rate", icon: "heart.fill", color: MedNexTheme.Colors.error, unit: "bpm") {
                    Chart(displayedVitals) { vital in
                        if let hr = vital.heartRate {
                            LineMark(x: .value("Date", vital.timestamp), y: .value("BPM", hr))
                                .foregroundStyle(MedNexTheme.Colors.error.gradient)
                                .interpolationMethod(.catmullRom)
                            AreaMark(x: .value("Date", vital.timestamp), y: .value("BPM", hr))
                                .foregroundStyle(MedNexTheme.Colors.error.opacity(0.1).gradient)
                                .interpolationMethod(.catmullRom)
                            PointMark(x: .value("Date", vital.timestamp), y: .value("BPM", hr))
                                .foregroundStyle(MedNexTheme.Colors.error)
                                .symbolSize(20)
                        }
                    }
                    .chartYScale(domain: 55...100)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            AxisGridLine()
                                .foregroundStyle(MedNexTheme.Colors.separator)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            AxisGridLine()
                                .foregroundStyle(MedNexTheme.Colors.separator)
                        }
                    }
                    .frame(height: 180)
                }
                
                // Blood Pressure Chart
                chartCard(title: "Blood Pressure", icon: "waveform.path.ecg", color: MedNexTheme.Colors.info, unit: "mmHg") {
                    Chart(displayedVitals) { vital in
                        if let sys = vital.bloodPressureSystolic {
                            LineMark(x: .value("Date", vital.timestamp), y: .value("Systolic", sys))
                                .foregroundStyle(by: .value("Type", "Systolic"))
                                .interpolationMethod(.catmullRom)
                        }
                        if let dia = vital.bloodPressureDiastolic {
                            LineMark(x: .value("Date", vital.timestamp), y: .value("Diastolic", dia))
                                .foregroundStyle(by: .value("Type", "Diastolic"))
                                .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartForegroundStyleScale(["Systolic": MedNexTheme.Colors.error, "Diastolic": MedNexTheme.Colors.info])
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            AxisGridLine()
                                .foregroundStyle(MedNexTheme.Colors.separator)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            AxisGridLine()
                                .foregroundStyle(MedNexTheme.Colors.separator)
                        }
                    }
                    .chartLegend(.visible)
                    .chartLegend(position: .bottom)

                    .frame(height: 180)
                }
                
                // SpO2 Chart
                chartCard(title: "Oxygen Saturation", icon: "lungs.fill", color: MedNexTheme.Colors.primary, unit: "%") {
                    Chart(displayedVitals) { vital in
                        if let spo2 = vital.oxygenSaturation {
                            LineMark(x: .value("Date", vital.timestamp), y: .value("SpO2", spo2))
                                .foregroundStyle(MedNexTheme.Colors.primary.gradient)
                                .interpolationMethod(.catmullRom)
                            AreaMark(x: .value("Date", vital.timestamp), y: .value("SpO2", spo2))
                                .foregroundStyle(MedNexTheme.Colors.primary.opacity(0.15).gradient)
                                .interpolationMethod(.catmullRom)
                            PointMark(x: .value("Date", vital.timestamp), y: .value("SpO2", spo2))
                                .foregroundStyle(MedNexTheme.Colors.primary)
                                .symbolSize(20)
                        }
                    }
                    .chartYScale(domain: 90...100)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            AxisGridLine()
                                .foregroundStyle(MedNexTheme.Colors.separator)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            AxisGridLine()
                                .foregroundStyle(MedNexTheme.Colors.separator)
                        }
                    }
                    .frame(height: 180)
                }
                
                // Summary Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                    if let latest = dataStore.vitalRecords.first {
                        StatCard(title: "Heart Rate", value: latest.heartRateFormatted ?? "—", icon: "heart.fill", tintColor: MedNexTheme.Colors.error)
                        StatCard(title: "Blood Pressure", value: latest.bloodPressureFormatted ?? "—", icon: "waveform.path.ecg", tintColor: MedNexTheme.Colors.info)
                        StatCard(title: "SpO₂", value: latest.spO2Formatted ?? "—", icon: "lungs.fill", tintColor: MedNexTheme.Colors.primary)
                        StatCard(title: "Temperature", value: latest.temperatureFormatted ?? "—", icon: "thermometer.medium", tintColor: MedNexTheme.Colors.warning)
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
            }
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Health")
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.3)) {
                animateCharts = true
            }
        }
    }
    
    private var displayedVitals: [VitalRecord] {
        let count: Int
        switch selectedPeriod {
        case .week: count = 7
        case .month: count = 14
        case .threeMonths: count = 14
        }
        return Array(dataStore.vitalRecords.prefix(count)).reversed()
    }
    
    @ViewBuilder
    private func chartCard<ChartContent: View>(title: String, icon: String, color: Color, unit: String, @ViewBuilder chart: @escaping () -> ChartContent) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                    Text(title)
                        .font(MedNexTheme.Typography.headline)
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    Spacer()
                    Text(unit)
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
                
                chart()
            }
        }
        .clipped()
        .padding(.horizontal, MedNexTheme.Spacing.md)
        .opacity(animateCharts ? 1 : 0)
    }
}

enum TimePeriod: String, CaseIterable {
    case week = "7 Days"
    case month = "30 Days"
    case threeMonths = "90 Days"
}
