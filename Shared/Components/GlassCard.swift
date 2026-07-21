//
//  GlassCard.swift
//  MedNex
//
//  Elevated card — adaptive light/dark theme style.

import SwiftUI

struct GlassCard<Content: View>: View {
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
            .foregroundStyle(MedNexTheme.Colors.textPrimary)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: cornerRadius)
            )
            .accessibilityElement(children: .contain)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Adaptive Card")
                    .font(MedNexTheme.Typography.title3)
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                Text("Clean adaptive theme card")
                    .font(MedNexTheme.Typography.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
