//
//  SettingsDetailView.swift
//  MedNex
//
//  Reusable settings detail placeholder view used across Patient, Staff, and Admin modules.

import SwiftUI

struct SettingsDetailView: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                GlassCard {
                    VStack(spacing: MedNexTheme.Spacing.md) {
                        Image(systemName: icon)
                            .font(.system(size: 44))
                            .foregroundStyle(MedNexTheme.Colors.primary)
                            .padding(.top, MedNexTheme.Spacing.md)
                        
                        Text(description)
                            .font(MedNexTheme.Typography.body)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        StatusBadge(text: "Coming Soon", color: MedNexTheme.Colors.info, icon: "clock.fill")
                            .padding(.top, MedNexTheme.Spacing.sm)
                    }
                    .padding(MedNexTheme.Spacing.lg)
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
            }
            .padding(.top, MedNexTheme.Spacing.lg)
        }
        .navigationTitle(title)
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
    }
}
