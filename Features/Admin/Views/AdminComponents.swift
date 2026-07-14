//
//  AdminComponents.swift
//  MedNex
//
//  Shared components for a unified Admin UI system.
//  All admin screens must use these for visual consistency.
//  Premium design — Apple Health / Stripe dashboard inspired.

import SwiftUI

// MARK: - Admin Profile Header

/// Used at the top of ALL detail screens (Doctor, Patient, Staff, Bill).
struct AdminProfileHeader: View {
    let name: String
    var imageURL: String?
    var subtitle: String?
    var badge: String?
    var badgeColor: Color = MedNexTheme.Colors.info
    var avatarColor: Color = MedNexTheme.Colors.primary
    var size: CGFloat = 80
    
    var body: some View {
        VStack(spacing: MedNexTheme.Spacing.xs) {
            AvatarView(
                name: name.isEmpty ? "?" : name,
                imageURL: imageURL,
                size: size,
                backgroundColor: avatarColor
            )
            
            Text(name.isEmpty ? "Unknown" : name)
                .font(.title2.weight(.semibold))
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
            }
            
            if let badge, !badge.isEmpty {
                Text(badge)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(badgeColor.opacity(0.12), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MedNexTheme.Spacing.sm)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

// MARK: - Admin Detail Row

/// Standard key–value row used in detail view sections.
struct AdminDetailRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = MedNexTheme.Colors.textPrimary
    
    var body: some View {
        HStack(spacing: MedNexTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, MedNexTheme.Spacing.xxxs)
    }
}

// MARK: - Admin Metric Row

/// Large metric display for dashboard overview: icon + label + big value.
/// Upgraded with icon background for premium feel.
struct AdminMetricRow: View {
    let icon: String
    let label: String
    let value: String
    var iconColor: Color = MedNexTheme.Colors.primary
    
    var body: some View {
        HStack(spacing: MedNexTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
            
            Text(label)
                .font(.body)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
        }
        .padding(.vertical, MedNexTheme.Spacing.xxs)
    }
}

// MARK: - Admin Stat Item

/// Compact breakdown item used in dashboard for sub-metrics.
/// Upgraded with icon background tint.
struct AdminStatItem: View {
    let icon: String
    let label: String
    let count: String
    var color: Color = .secondary
    
    var body: some View {
        HStack(spacing: MedNexTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            
            Spacer()
            
            Text(count)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
        }
        .padding(.vertical, MedNexTheme.Spacing.xxxs)
    }
}

// MARK: - Admin Appointment Row

/// Reusable appointment row used in Doctor and Patient detail views.
struct AdminAppointmentRow: View {
    let title: String
    let date: Date
    let status: AppointmentStatus
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Text(status.rawValue.capitalized)
                .font(.caption.weight(.medium))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.12), in: Capsule())
        }
        .padding(.vertical, MedNexTheme.Spacing.xxxs)
    }
    
    private var statusColor: Color {
        switch status {
        case .completed: return MedNexTheme.Colors.success
        case .cancelled: return MedNexTheme.Colors.error
        default: return MedNexTheme.Colors.warning
        }
    }
}

// MARK: - Admin Bill Row

/// Compact bill row for patient detail views.
struct AdminBillRow: View {
    let amount: Double
    let date: Date
    let status: BillStatus
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                Text("₹\(Int(amount))")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Text(status.displayName)
                .font(.caption.weight(.medium))
                .foregroundStyle(status == .paid ? MedNexTheme.Colors.success : MedNexTheme.Colors.warning)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background((status == .paid ? MedNexTheme.Colors.success : MedNexTheme.Colors.warning).opacity(0.12), in: Capsule())
        }
        .padding(.vertical, MedNexTheme.Spacing.xxxs)
    }
}

// MARK: - Admin Section Header

/// Styled section header for admin screens with optional action.
struct AdminSectionHeader: View {
    let title: String
    var icon: String?
    var count: Int?
    var actionLabel: String?
    var action: (() -> Void)?
    
    var body: some View {
        HStack(spacing: MedNexTheme.Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
            
            Text(title)
            
            if let count {
                Text("(\(count))")
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
            
            Spacer()
            
            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
            }
        }
    }
}
