//
//  GlassStyles.swift
//  MedNex
//
//  Light mode view modifiers and button styles.

import SwiftUI

// MARK: - Light Card Modifiers

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = MedNexTheme.CornerRadius.lg
    
    func body(content: Content) -> some View {
        content
            .background(
                Color(white: 0.94),
                in: RoundedRectangle(cornerRadius: cornerRadius)
            )
    }
}

struct GlassButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Color(white: 0.92),
                in: Capsule()
            )
    }
}

struct GlassPillModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                MedNexTheme.Colors.elevatedBackground,
                in: Capsule()
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MedNexTheme.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                MedNexTheme.Colors.primary,
                in: Capsule()
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(MedNexTheme.Animation.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MedNexTheme.Typography.headline)
            .foregroundStyle(MedNexTheme.Colors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Color(white: 0.94),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(MedNexTheme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(MedNexTheme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = MedNexTheme.CornerRadius.lg) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
    
    func glassButton() -> some View {
        modifier(GlassButtonModifier())
    }
    
    func glassPill() -> some View {
        modifier(GlassPillModifier())
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var medNexPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var medNexSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
