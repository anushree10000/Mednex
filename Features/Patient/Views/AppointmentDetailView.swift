//
//  AppointmentDetailView.swift
//  MedNex
//
//  Redesigned following Apple Human Interface Guidelines:
//  - Prominent header with doctor info
//  - Grouped inset sections
//  - Clear action buttons
//  - Smooth animations

import SwiftUI

struct AppointmentDetailView: View {
    let appointment: Appointment
    @State private var showCancelAlert = false
    @State private var showReschedule = false
    @State private var newDate = Date()
    @State private var rating = 0
    @State private var reviewText = ""
    @State private var animateContent = false
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // MARK: - Doctor Profile Header
                doctorHeader
                
                // MARK: - Status Pill
                statusPill
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 10)
                
                // MARK: - Appointment Info Section
                appointmentInfoSection
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 15)
                
                // MARK: - Clinical Notes
                if !appointment.notes.isEmpty {
                    notesSection
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                }
                
                // MARK: - Action Buttons
                if appointment.canCancel {
                    actionButtons
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 25)
                }
                
                // MARK: - Review Section
                if appointment.status == .completed {
                    reviewSection
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 25)
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.vertical, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Appointment")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.background.ignoresSafeArea())
        .onAppear {
            if let r = appointment.rating {
                rating = r
                reviewText = appointment.review ?? ""
            }
            withAnimation(MedNexTheme.Animation.smooth.delay(0.15)) {
                animateContent = true
            }
        }
        .sheet(isPresented: $showReschedule) {
            rescheduleSheet
        }
        .alert("Cancel Appointment?", isPresented: $showCancelAlert) {
            Button("Keep", role: .cancel) {}
            Button("Cancel Appointment", role: .destructive) {
                HapticManager.warning()
                dataStore.cancelAppointment(appointment.id)
                dataStore.addNotification(
                    title: "Appointment Cancelled",
                    message: "Your appointment with Dr. \(appointment.doctorName) on \(appointment.dateTime.shortDate) has been cancelled.",
                    type: .appointmentCancelled
                )
                dismiss()
            }
        } message: {
            Text("Are you sure you want to cancel this appointment? This action cannot be undone.")
        }
    }
    
    // MARK: - Doctor Header
    private var doctorHeader: some View {
        VStack(spacing: MedNexTheme.Spacing.md) {
            // Doctor Avatar
            AvatarView(name: appointment.doctorName, imageURL: dataStore.doctors.first(where: { $0.id == appointment.doctorId })?.profileImageURL, size: 80, backgroundColor: MedNexTheme.Colors.doctorTint)
                .shadow(color: MedNexTheme.Colors.doctorTint.opacity(0.3), radius: 12, x: 0, y: 6)
            
            // Doctor Info
            VStack(spacing: 4) {
                Text(appointment.doctorName)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(appointment.specialty.rawValue)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(MedNexTheme.Colors.primary)
                
                if let doc = dataStore.doctors.first(where: { $0.id == appointment.doctorId }) {
                    Text(doc.education)
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MedNexTheme.Spacing.lg)
        .opacity(animateContent ? 1 : 0)
        .scaleEffect(animateContent ? 1 : 0.95)
    }
    
    // MARK: - Status Pill
    private var statusPill: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.system(size: 14, weight: .semibold))
            Text(appointment.status.displayName)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
        .foregroundStyle(Color(hex: appointment.status.color))
        .padding(.horizontal, MedNexTheme.Spacing.lg)
        .padding(.vertical, MedNexTheme.Spacing.sm)
        .background(Color(hex: appointment.status.color).opacity(0.12), in: Capsule())
    }
    
    private var statusIcon: String {
        switch appointment.status {
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .inProgress: return "play.circle.fill"
        case .noShow: return "eye.slash.fill"
        default: return "clock.fill"
        }
    }
    
    // MARK: - Appointment Info Section
    private var appointmentInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            Text("APPOINTMENT DETAILS")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xs)
            
            VStack(spacing: 0) {
                infoRow(icon: "calendar", title: "Date", value: appointment.dateTime.medicalFormat, isFirst: true)
                
                Divider().padding(.leading, 52)
                
                infoRow(icon: "clock.fill", title: "Time", value: "\(appointment.dateTime.timeOnly) – \(appointment.endTime.timeOnly)")
                
                Divider().padding(.leading, 52)
                
                infoRow(icon: "stethoscope", title: "Visit Type", value: appointment.type.displayName)
                
                Divider().padding(.leading, 52)
                
                infoRow(icon: "creditcard.fill", title: "Payment",
                        value: appointment.billingStatus.displayName,
                        valueColor: appointment.billingStatus == .paid ? MedNexTheme.Colors.success : MedNexTheme.Colors.textPrimary,
                        isLast: true)
            }
            .background(
                RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg)
                    .fill(MedNexTheme.Colors.cardBackground)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private func infoRow(
        icon: String,
        title: String,
        value: String,
        valueColor: Color = MedNexTheme.Colors.textPrimary,
        isFirst: Bool = false,
        isLast: Bool = false
    ) -> some View {
        HStack(spacing: MedNexTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(MedNexTheme.Colors.primary)
                .frame(width: 28, height: 28)
                .background(MedNexTheme.Colors.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            
            Text(title)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, MedNexTheme.Spacing.md)
        .padding(.vertical, 14)
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CLINICAL NOTES")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xs)
            
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                HStack(spacing: MedNexTheme.Spacing.sm) {
                    Image(systemName: "note.text")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(MedNexTheme.Colors.info)
                        .frame(width: 28, height: 28)
                        .background(MedNexTheme.Colors.info.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    
                    Text("Diagnosis & Notes")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                }
                
                Text(appointment.notes)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(MedNexTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg)
                    .fill(MedNexTheme.Colors.cardBackground)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: MedNexTheme.Spacing.sm) {
            Button {
                HapticManager.selection()
                showReschedule = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Reschedule Appointment")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(MedNexTheme.Colors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg)
                        .fill(MedNexTheme.Colors.primary.opacity(0.1))
                )
            }
            
            Button {
                HapticManager.warning()
                showCancelAlert = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Cancel Appointment")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg)
                        .fill(Color.red.opacity(0.08))
                )
            }
        }
    }
    
    // MARK: - Review Section
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOUR FEEDBACK")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xs)
            
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                // Star Rating
                HStack(spacing: 14) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(star <= rating ? MedNexTheme.Colors.accent : MedNexTheme.Colors.textTertiary.opacity(0.4))
                            .scaleEffect(star <= rating ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)
                            .onTapGesture {
                                HapticManager.light()
                                withAnimation { rating = star }
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MedNexTheme.Spacing.xs)
                
                // Review Text Field
                TextField("How was your visit? (optional)", text: $reviewText, axis: .vertical)
                    .lineLimit(3...5)
                    .font(.system(.body, design: .rounded))
                    .padding(MedNexTheme.Spacing.sm)
                    .background(MedNexTheme.Colors.background.opacity(0.6), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.md)
                            .stroke(MedNexTheme.Colors.textTertiary.opacity(0.15), lineWidth: 1)
                    )
                
                // Submit Button
                Button {
                    dataStore.rateAppointment(id: appointment.id, rating: rating, review: reviewText)
                    HapticManager.success()
                    dismiss()
                } label: {
                    Text("Submit Feedback")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg)
                                .fill(rating == 0 ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.primary)
                        )
                }
                .disabled(rating == 0)
            }
            .padding(MedNexTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg)
                    .fill(MedNexTheme.Colors.cardBackground)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Reschedule Sheet
    private var rescheduleSheet: some View {
        NavigationStack {
            VStack(spacing: MedNexTheme.Spacing.md) {
                DatePicker("New Date & Time", selection: $newDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .tint(MedNexTheme.Colors.primary)
                    .padding()
                    .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.lg))
                    .padding(.horizontal)
                
                Button("Confirm Reschedule") {
                    dataStore.rescheduleAppointment(appointment.id, to: newDate)
                    HapticManager.success()
                    showReschedule = false
                    dismiss()
                }
                .buttonStyle(.medNexPrimary)
                .padding(.horizontal)
                
                Spacer()
            }
            .background(MedNexTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showReschedule = false }
                }
            }
        }
    }
}
