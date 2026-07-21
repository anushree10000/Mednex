//
//  StatCard.swift
//  MedNex
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var trend: TrendDirection?
    var trendValue: String?
    var tintColor: Color = MedNexTheme.Colors.primary
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(tintColor)
                        .frame(width: 36, height: 36)
                        .background(tintColor.opacity(0.15), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                    
                    Spacer()
                    
                    if let trend, let trendValue {
                        HStack(spacing: 2) {
                            Image(systemName: trend.icon)
                                .font(.caption2.bold())
                            Text(trendValue)
                                .font(MedNexTheme.Typography.caption)
                        }
                        .foregroundStyle(trend.color)
                    }
                }
                
                Text(value)
                    .font(MedNexTheme.Typography.title)
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    .contentTransition(.numericText())
                
                Text(title)
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(statAccessibilityLabel)
    }
    
    private var statAccessibilityLabel: String {
        var label = "\(title): \(value)"
        if let trend, let trendValue {
            let direction = trend == .up ? "up" : trend == .down ? "down" : "stable"
            label += ", trending \(direction) \(trendValue)"
        }
        return label
    }
}

enum TrendDirection {
    case up, down, stable
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return MedNexTheme.Colors.success
        case .down: return MedNexTheme.Colors.error
        case .stable: return MedNexTheme.Colors.textSecondary
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        StatCard(
            title: "Total Patients",
            value: "1,234",
            icon: "person.2.fill",
            trend: .up,
            trendValue: "+12%"
        )
        .padding()
    }
}
