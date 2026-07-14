import SwiftUI

struct DoctorCard<Content: View>: View {
    let content: () -> Content
    var cornerRadius: CGFloat = MedNexTheme.CornerRadius.lg
    var padding: CGFloat = MedNexTheme.Spacing.md

    init(
        cornerRadius: CGFloat = MedNexTheme.CornerRadius.lg,
        padding: CGFloat = MedNexTheme.Spacing.md,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
            )
    }
}

// MARK: - Apple HIG Inset Grouped Section
/// A container that mimics iOS native inset grouped table view sections.
/// Wraps multiple rows in a single rounded container with dividers between them.
struct DoctorGroupedSection<Content: View>: View {
    var header: String? = nil
    var footer: String? = nil
    let content: () -> Content

    init(
        header: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.header = header
        self.footer = footer
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
            if let header {
                Text(header.uppercased())
                    .font(.system(.footnote, design: .default, weight: .semibold))
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.horizontal, MedNexTheme.Spacing.md + MedNexTheme.Spacing.xs)
                    .padding(.top, MedNexTheme.Spacing.xs)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg, style: .continuous))

            if let footer {
                Text(footer)
                    .font(.system(.footnote, design: .default))
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.horizontal, MedNexTheme.Spacing.md + MedNexTheme.Spacing.xs)
            }
        }
    }
}

// MARK: - Grouped Section Row
/// A single row styled for use inside `DoctorGroupedSection`.
/// Includes optional leading indent for dividers.
struct DoctorGroupedRow<Content: View>: View {
    var showDivider: Bool = true
    var dividerLeadingPadding: CGFloat = 60
    let content: () -> Content

    init(
        showDivider: Bool = true,
        dividerLeadingPadding: CGFloat = 60,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.showDivider = showDivider
        self.dividerLeadingPadding = dividerLeadingPadding
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            content()
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.vertical, 11)
                .contentShape(Rectangle())

            if showDivider {
                Divider()
                    .padding(.leading, dividerLeadingPadding)
            }
        }
    }
}

private struct DoctorFlowBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

extension View {
    func doctorFlowBackground() -> some View {
        modifier(DoctorFlowBackgroundModifier())
    }
}
