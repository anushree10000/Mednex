//
//  SharedComponents.swift
//  MedNex
//
//  Native iOS shared components — Apple HIG compliant.
//  Uses system semantic colors for auto-contrast.

import SwiftUI

// MARK: - Loading View
struct LoadingView: View {
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: MedNexTheme.Spacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(MedNexTheme.Colors.primary)
            
            Text(message)
                .font(MedNexTheme.Typography.subheadline)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: MedNexTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(MedNexTheme.Colors.primary.opacity(0.6))
            
            Text(title)
                .font(MedNexTheme.Typography.title3)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            
            Text(message)
                .font(MedNexTheme.Typography.body)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MedNexTheme.Spacing.xl)
            
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(.medNexPrimary)
                .padding(.horizontal, MedNexTheme.Spacing.jumbo)
                .padding(.top, MedNexTheme.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Search Bar
struct MedNexSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    
    var body: some View {
        HStack(spacing: MedNexTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(MedNexTheme.Colors.textTertiary)
            
            TextField(placeholder, text: $text)
                .font(MedNexTheme.Typography.body)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                .autocorrectionDisabled()
            
            if !text.isEmpty {
                Button {
                    text = ""
                    HapticManager.light()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
            }
        }
        .padding(MedNexTheme.Spacing.sm)
        .background(MedNexTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Search")
        .accessibilityHint("Type to filter results")
    }
}

// MARK: - Avatar View
struct AvatarView: View {
    let name: String
    var imageURL: String?
    var size: CGFloat = 44
    var backgroundColor: Color = MedNexTheme.Colors.primary
    
    private var normalizedImageURL: URL? {
        guard let imageURL else { return nil }
        let trimmed = imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }
    
    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }
    
    var body: some View {
        Group {
            if let normalizedImageURL {
                AsyncImage(url: normalizedImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        initialsFallback
                    }
                }
            } else {
                initialsFallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("Avatar for \(name)")
    }

    private var initialsFallback: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.opacity(0.25))

            Text(initials)
                .font(.system(size: size * 0.35, weight: .semibold, design: .rounded))
                .foregroundStyle(backgroundColor)
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String
    let color: Color
    var icon: String?
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(MedNexTheme.Typography.caption.weight(.medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, MedNexTheme.Spacing.xs)
        .padding(.vertical, MedNexTheme.Spacing.xxs)
        .background(color.opacity(0.15), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(text)")
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: String?
    var onAction: (() -> Void)?
    
    var body: some View {
        HStack {
            Text(title)
                .font(MedNexTheme.Typography.headline)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            
            Spacer()
            
            if let action, let onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(MedNexTheme.Typography.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }
}
