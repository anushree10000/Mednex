//
//  Theme.swift
//  MedNex
//
//  100% Native iOS design tokens — Apple HIG compliant.
//  Uses system semantic colors for automatic light/dark mode support.

import SwiftUI

// MARK: - MedNex Design Tokens
enum MedNexTheme {
    
    // MARK: Colors — System Semantic (Auto light/dark)
    enum Colors {
        // Primary — Apple Health green
        static let primary = Color(hex: "30D158")
        static let primaryStart = Color(hex: "30D158")
        static let primaryEnd = Color(hex: "34C759")
        
        // Accent
        static let accent = Color(hex: "FF9F0A")
        static let accentLight = Color(hex: "FFD60A")
        
        // Semantic — Apple system colors
        static let success = Color(hex: "30D158")
        static let warning = Color(hex: "FF9F0A")
        static let error = Color(hex: "FF453A")
        static let info = Color(hex: "0A84FF")
        
        // Text — System adaptive (auto dark mode)
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        
        // Surfaces — System adaptive (auto dark mode)
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)
        static let cardBackground = Color(.secondarySystemGroupedBackground)
        static let elevatedBackground = Color(.tertiarySystemGroupedBackground)
        static let separator = Color(.separator)
        
        // Role-based tints
        static let patientTint = Color(hex: "30D158")
        static let doctorTint = Color(hex: "0A84FF")
        static let adminTint = Color(hex: "BF5AF2")
        static let nurseTint = Color(hex: "FF375F")
        static let labTechTint = Color(hex: "FF9F0A")
        static let pharmacistTint = Color(hex: "64D2FF")
        static let nightShiftTint = Color(hex: "6366F1")
        
        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [primaryStart, primaryEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accentGradient = LinearGradient(
            colors: [Color(hex: "FF9F0A"), Color(hex: "FFD60A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardGradient = LinearGradient(
            colors: [cardBackground, cardBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Health-app-inspired tinted background — adapts to dark mode
        static let healthGradient = LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: Typography — SF Pro (Apple native)
    enum Typography {
        // SF Pro Rounded for display/titles
        static let largeTitle = Font.system(.largeTitle, design: .default, weight: .bold)
        static let title = Font.system(.title, design: .default, weight: .bold)
        static let title2 = Font.system(.title2, design: .default, weight: .semibold)
        static let title3 = Font.system(.title3, design: .default, weight: .semibold)
        
        // SF Pro for body/UI text
        static let headline = Font.system(.headline, design: .default, weight: .semibold)
        static let body = Font.system(.body, design: .default)
        static let callout = Font.system(.callout, design: .default)
        static let subheadline = Font.system(.subheadline, design: .default)
        static let footnote = Font.system(.footnote, design: .default)
        static let caption = Font.system(.caption, design: .default)
        static let caption2 = Font.system(.caption2, design: .default)
        
        // Monospaced for data
        static let monoBody = Font.system(.body, design: .monospaced)
        static let monoCaption = Font.system(.caption, design: .monospaced)
    }
    
    // MARK: Spacing — Apple HIG standard
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let jumbo: CGFloat = 48
    }
    
    // MARK: Corner Radius
    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let pill: CGFloat = 100
    }
    
    // MARK: Shadows (subtle depth)
    enum Shadows {
        static let sm = ShadowStyle(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        static let md = ShadowStyle(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        static let lg = ShadowStyle(color: .black.opacity(0.16), radius: 16, x: 0, y: 8)
    }
    
    // MARK: Animation
    enum Animation {
        static let smooth = SwiftUI.Animation.spring(.smooth)
        static let bouncy = SwiftUI.Animation.spring(.bouncy)
        static let snappy = SwiftUI.Animation.spring(.snappy)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
    
    // MARK: Layout
    enum Layout {
        static let minTouchTarget: CGFloat = 44
        static let maxContentWidth: CGFloat = 700
        static let cardMinHeight: CGFloat = 60
    }
}

// MARK: - Shadow Style Helper
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func medNexShadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
