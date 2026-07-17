//
//  DoctorProfileDetailView.swift
//  MedNex
//

import SwiftUI

struct DoctorProfileDetailView: View {
    let doctor: Doctor
    let onSelect: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MedNexTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: MedNexTheme.Spacing.sm) {
                        AvatarView(name: doctor.name, imageURL: doctor.profileImageURL, size: 100, backgroundColor: MedNexTheme.Colors.doctorTint)
                        
                        Text(doctor.name)
                            .font(MedNexTheme.Typography.title)
                        Text(doctor.specialty.rawValue)
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                    }
                    .padding(.top, MedNexTheme.Spacing.lg)
                    
                    // Stats
                    HStack(spacing: MedNexTheme.Spacing.lg) {
                        statItem(title: "Experience", value: "\(doctor.experience) yrs", icon: "briefcase.fill")
                        statItem(title: "Rating", value: String(format: "%.1f", doctor.rating), icon: "star.fill", tint: MedNexTheme.Colors.accent)
                        statItem(title: "Fee", value: "₹\(Int(doctor.consultationFee))", icon: "banknote.fill")
                    }
                    
                    // Bio
                    if !doctor.bio.isEmpty {
                        sectionCard(title: "About", icon: "person.text.rectangle") {
                            Text(doctor.bio)
                                .font(MedNexTheme.Typography.body)
                                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                .lineSpacing(4)
                        }
                    }
                    
                    // Education
                    if !doctor.education.isEmpty {
                        sectionCard(title: "Education", icon: "graduationcap.fill") {
                            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                                HStack(alignment: .top, spacing: MedNexTheme.Spacing.sm) {
                                    Image(systemName: "building.columns.fill")
                                        .foregroundStyle(MedNexTheme.Colors.primary)
                                        .frame(width: 24, height: 24)
                                    Text(doctor.education)
                                        .font(MedNexTheme.Typography.body)
                                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                }
                            }
                        }
                    }
                    
                    // Languages
                    if !doctor.languages.isEmpty {
                        sectionCard(title: "Languages", icon: "bubble.left.and.bubble.right.fill") {
                            HStack {
                                ForEach(doctor.languages, id: \.self) { lang in
                                    Text(lang)
                                        .font(MedNexTheme.Typography.subheadline)
                                        .padding(.horizontal, MedNexTheme.Spacing.sm)
                                        .padding(.vertical, 4)
                                        .background(MedNexTheme.Colors.primary.opacity(0.1), in: Capsule())
                                        .foregroundStyle(MedNexTheme.Colors.primary)
                                }
                            }
                        }
                    }
                    
                    // Reviews (Mock)
                    reviewsSection
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    HapticManager.selection()
                    dismiss()
                    onSelect()
                } label: {
                    Text("Book Appointment")
                }
                .buttonStyle(.medNexPrimary)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.vertical, MedNexTheme.Spacing.sm)
                .background(
                    LinearGradient(
                        colors: [
                            MedNexTheme.Colors.background.opacity(0),
                            MedNexTheme.Colors.background
                        ],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.35)
                    )
                    .ignoresSafeArea()
                )
            }
            .navigationTitle("Doctor Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func statItem(title: String, value: String, icon: String, tint: Color = MedNexTheme.Colors.primary) -> some View {
        VStack(spacing: MedNexTheme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.1), in: Circle())
            Text(value)
                .font(MedNexTheme.Typography.headline)
            Text(title)
                .font(MedNexTheme.Typography.caption)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
        }
    }
    
    private func sectionCard(title: String, icon: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        GlassCard(padding: MedNexTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                Label {
                    Text(title)
                        .font(MedNexTheme.Typography.headline)
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                } icon: {
                    Image(systemName: icon)
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
                Divider().overlay(MedNexTheme.Colors.separator)
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var reviewsSection: some View {
        GlassCard(padding: MedNexTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                HStack {
                    Label {
                        Text("Patient Reviews")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    } icon: {
                        Image(systemName: "star.bubble.fill")
                            .foregroundStyle(MedNexTheme.Colors.primary)
                    }
                    Spacer()
                    Button("See All") { }
                        .font(MedNexTheme.Typography.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
                
                Divider().overlay(MedNexTheme.Colors.separator)
                
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                    reviewRow(author: "Anonymous", rating: 5, date: "2 weeks ago", text: "Dr. \(doctor.name.split(separator: " ").last ?? "Doctor") was very attentive and took the time to explain everything clearly. Highly recommended!")
                    
                    Divider().overlay(MedNexTheme.Colors.separator.opacity(0.5))
                    
                    reviewRow(author: "Sarah M.", rating: 4, date: "1 month ago", text: "Great consultation, but had to wait around 15 mins past my appointment time. Overall good experience.")
                }
            }
        }
    }
    
    private func reviewRow(author: String, rating: Int, date: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
            HStack {
                Text(author)
                    .font(MedNexTheme.Typography.subheadline.weight(.semibold))
                Spacer()
                Text(date)
                    .font(MedNexTheme.Typography.caption2)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
            
            HStack(spacing: 2) {
                ForEach(0..<5) { i in
                    Image(systemName: i < rating ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(MedNexTheme.Colors.warning)
                }
            }
            .padding(.bottom, 2)
            
            Text(text)
                .font(MedNexTheme.Typography.caption)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                .lineLimit(3)
        }
    }
}
