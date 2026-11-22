//
//  PatientHomeView.swift
//  MedNex
//

import SwiftUI

struct PatientHomeView: View {
    let appState: AppState
    @Binding var showProfile: Bool
    @State private var showBooking = false
    @State private var showLabRequest = false
    @State private var showRecords = false
    @State private var showMedicines = false
    @State private var animateCards = false
    @Environment(DataStore.self) private var dataStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Welcome Header
                welcomeHeader
                
                // Quick Actions
                quickActions
                
                // Upcoming Appointment Card
                upcomingAppointmentCard
                
                // Health Summary
                healthSummarySection
                
                // Recent Activity
                recentActivitySection
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Home")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) {
                animateCards = true
            }
        }
        .sheet(isPresented: $showBooking) {
            AppointmentBookingView()
        }
        .sheet(isPresented: $showLabRequest) {
            NavigationStack {
                PatientLabRequestView()
            }
        }
        .navigationDestination(isPresented: $showRecords) {
            MedicalRecordsView()
        }
        .navigationDestination(isPresented: $showMedicines) {
            PrescriptionTrackerView()
        }
    }
    
    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                Text("Good \(greeting),")
                    .font(MedNexTheme.Typography.subheadline)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                
                Text(appState.currentUser?.displayName ?? "Patient")
                    .font(MedNexTheme.Typography.title2)
            }
            
            Spacer()
            
            // User Avatar → opens profile
            Button { showProfile = true } label: {
                AvatarView(name: appState.currentUser?.displayName ?? "P", size: 48, backgroundColor: MedNexTheme.Colors.patientTint)
            }
        }
        .padding(.top, MedNexTheme.Spacing.sm)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 15)
    }
    
    // MARK: - Quick Actions
    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MedNexTheme.Spacing.sm) {
                quickActionButton(icon: "calendar.badge.plus", title: "Book", color: MedNexTheme.Colors.primary) {
                    showBooking = true
                }
                quickActionButton(icon: "doc.text.fill", title: "Records", color: MedNexTheme.Colors.info) {
                    showRecords = true
                }
                quickActionButton(icon: "flask.fill", title: "Lab Test", color: MedNexTheme.Colors.warning) {
                    showLabRequest = true
                }
                quickActionButton(icon: "pills.fill", title: "Medicines", color: MedNexTheme.Colors.success) {
                    showMedicines = true
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 15)
    }
    
    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            VStack(spacing: MedNexTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md))
                
                Text(title)
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
            }
            .frame(width: 72)
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to open \(title)")
    }
    
    // MARK: - Upcoming Appointment
    private var upcomingAppointmentCard: some View {
        let upcoming = dataStore.upcomingAppointments.first
        
        return Group {
            if let appointment = upcoming {
                GlassCard {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        SectionHeader(title: "Upcoming Appointment")
                        
                        HStack(spacing: MedNexTheme.Spacing.md) {
                            AvatarView(name: appointment.doctorName, size: 52, backgroundColor: MedNexTheme.Colors.doctorTint)
                            
                            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                                Text(appointment.doctorName)
                                    .font(MedNexTheme.Typography.headline)
                                
                                Text(appointment.specialty.rawValue)
                                    .font(MedNexTheme.Typography.subheadline)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                
                                HStack(spacing: MedNexTheme.Spacing.xs) {
                                    Image(systemName: "calendar")
                                    Text(appointment.dateTime.medicalFormat)
                                }
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.primary)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }
    
    // MARK: - Health Summary
    private var healthSummarySection: some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            SectionHeader(title: "Health Overview")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                StatCard(title: "Heart Rate", value: "72 bpm", icon: "heart.fill", trend: .stable, trendValue: "Normal", tintColor: MedNexTheme.Colors.error)
                StatCard(title: "Blood Pressure", value: "120/80", icon: "waveform.path.ecg", tintColor: MedNexTheme.Colors.info)
                StatCard(title: "SpO₂", value: "98%", icon: "lungs.fill", trend: .up, trendValue: "+1%", tintColor: MedNexTheme.Colors.primary)
                StatCard(title: "Steps Today", value: "6,842", icon: "figure.walk", trend: .up, trendValue: "+12%", tintColor: MedNexTheme.Colors.success)
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 25)
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            SectionHeader(title: "Recent Notifications")
            
            ForEach(dataStore.notifications.prefix(3)) { notification in
                GlassCard(padding: MedNexTheme.Spacing.sm) {
                    HStack(spacing: MedNexTheme.Spacing.sm) {
                        Image(systemName: notification.type.icon)
                            .foregroundStyle(notification.isRead ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.primary)
                            .frame(width: 36, height: 36)
                            .background(
                                (notification.isRead ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.primary).opacity(0.12),
                                in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(notification.title)
                                .font(MedNexTheme.Typography.subheadline.weight(.medium))
                                .foregroundStyle(notification.isRead ? MedNexTheme.Colors.textSecondary : MedNexTheme.Colors.textPrimary)
                            
                            Text(notification.body)
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Text(notification.createdAt.relative)
                            .font(MedNexTheme.Typography.caption2)
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                    }
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 30)
    }
    
    // MARK: - Helpers
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        default: return "Evening"
        }
    }
}
