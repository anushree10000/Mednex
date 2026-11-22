//
//  AppointmentBookingView.swift
//  MedNex
//

import SwiftUI

struct AppointmentBookingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedSpecialty: MedicalSpecialty?
    @State private var selectedDoctor: Doctor?
    @State private var selectedDate = Date()
    @State private var selectedSlot: String?
    @State private var appointmentType: AppointmentType = .consultation
    @State private var symptoms = ""
    @State private var showConfirmation = false
    @State private var step = 0
    
    @Environment(DataStore.self) private var dataStore
    
    private var doctors: [Doctor] { dataStore.doctors }
    private let timeSlots = ["9:00 AM", "9:30 AM", "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM", "2:00 PM", "2:30 PM", "3:00 PM", "3:30 PM", "4:00 PM", "4:30 PM"]
    
    var filteredDoctors: [Doctor] {
        var result = doctors
        if let specialty = selectedSpecialty {
            result = result.filter { $0.specialty == specialty }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.specialty.rawValue.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MedNexTheme.Spacing.lg) {
                    // Progress indicator
                    progressBar
                    
                    switch step {
                    case 0: specialtySelectionStep
                    case 1: doctorSelectionStep
                    case 2: dateTimeStep
                    default: confirmationStep
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Appointment Booked!", isPresented: $showConfirmation) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your appointment with \(selectedDoctor?.name ?? "") on \(selectedDate.shortDate) at \(selectedSlot ?? "") has been confirmed.")
            }
        }
        .presentationBackground(MedNexTheme.Colors.healthGradient)
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: MedNexTheme.Spacing.xxs) {
            ForEach(0..<4) { i in
                Capsule()
                    .fill(i <= step ? MedNexTheme.Colors.primary : MedNexTheme.Colors.primary.opacity(0.2))
                    .frame(height: 4)
                    .animation(MedNexTheme.Animation.smooth, value: step)
            }
        }
    }
    
    // MARK: - Step 1: Specialty Selection
    private var specialtySelectionStep: some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
            Text("Select Specialty")
                .font(MedNexTheme.Typography.title3)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            
            Text("Choose the medical department for your visit")
                .font(MedNexTheme.Typography.subheadline)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
            
            // Symptom input
            GlassCard {
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xs) {
                    Label("Describe your symptoms (optional)", systemImage: "text.bubble.fill")
                        .font(MedNexTheme.Typography.caption.weight(.medium))
                        .foregroundStyle(MedNexTheme.Colors.primary)
                    
                    TextField("e.g., headache, chest pain, skin rash...", text: $symptoms, axis: .vertical)
                        .lineLimit(2...4)
                        .font(MedNexTheme.Typography.body)
                }
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                ForEach(MedicalSpecialty.allCases.prefix(12)) { specialty in
                    Button {
                        HapticManager.selection()
                        selectedSpecialty = specialty
                        withAnimation(MedNexTheme.Animation.smooth) { step = 1 }
                    } label: {
                        GlassCard(padding: MedNexTheme.Spacing.sm) {
                            VStack(spacing: MedNexTheme.Spacing.xs) {
                                Image(systemName: specialty.icon)
                                    .font(.title2)
                                    .foregroundStyle(MedNexTheme.Colors.primary)
                                    .frame(width: 44, height: 44)
                                    .background(MedNexTheme.Colors.primary.opacity(0.1), in: Circle())
                                
                                Text(specialty.rawValue)
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Doctor Selection
    private var doctorSelectionStep: some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
            Button {
                withAnimation(MedNexTheme.Animation.smooth) { step = 0 }
            } label: {
                Label("Back to Specialties", systemImage: "chevron.left")
                    .font(MedNexTheme.Typography.subheadline)
            }
            
            Text("Choose Doctor")
                .font(MedNexTheme.Typography.title3)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            
            MedNexSearchBar(text: $searchText, placeholder: "Search doctors...")
            
            ForEach(filteredDoctors) { doctor in
                Button {
                    HapticManager.selection()
                    selectedDoctor = doctor
                    withAnimation(MedNexTheme.Animation.smooth) { step = 2 }
                } label: {
                    doctorCard(doctor)
                }
            }
        }
    }
    
    private func doctorCard(_ doctor: Doctor) -> some View {
        GlassCard {
            HStack(spacing: MedNexTheme.Spacing.md) {
                AvatarView(name: doctor.name, size: 56, backgroundColor: MedNexTheme.Colors.doctorTint)
                
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                    Text(doctor.name)
                        .font(MedNexTheme.Typography.headline)
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    
                    Text(doctor.specialty.rawValue)
                        .font(MedNexTheme.Typography.subheadline)
                        .foregroundStyle(MedNexTheme.Colors.primary)
                    
                    HStack(spacing: MedNexTheme.Spacing.md) {
                        Label("\(doctor.experience) yrs", systemImage: "briefcase.fill")
                        Label(String(format: "%.1f", doctor.rating), systemImage: "star.fill")
                            .foregroundStyle(MedNexTheme.Colors.accent)
                    }
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("₹\(Int(doctor.consultationFee))")
                        .font(MedNexTheme.Typography.headline)
                        .foregroundStyle(MedNexTheme.Colors.primary)
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
            }
        }
    }
    
    // MARK: - Step 3: Date & Time
    private var dateTimeStep: some View {
        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
            Button {
                withAnimation(MedNexTheme.Animation.smooth) { step = 1 }
            } label: {
                Label("Back to Doctors", systemImage: "chevron.left")
                    .font(MedNexTheme.Typography.subheadline)
            }
            
            if let doctor = selectedDoctor {
                GlassCard(padding: MedNexTheme.Spacing.sm) {
                    HStack {
                        AvatarView(name: doctor.name, size: 40, backgroundColor: MedNexTheme.Colors.doctorTint)
                        VStack(alignment: .leading) {
                            Text(doctor.name).font(MedNexTheme.Typography.headline).foregroundStyle(MedNexTheme.Colors.textPrimary)
                            Text(doctor.specialty.rawValue).font(MedNexTheme.Typography.caption).foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
            
            Text("Select Date & Time")
                .font(MedNexTheme.Typography.title3)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            
            DatePicker("Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(MedNexTheme.Colors.primary)
                .glassCard()
            
            Text("Available Slots")
                .font(MedNexTheme.Typography.headline)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                ForEach(timeSlots, id: \.self) { slot in
                    Button {
                        HapticManager.selection()
                        selectedSlot = slot
                    } label: {
                        Text(slot)
                            .font(MedNexTheme.Typography.subheadline)
                            .foregroundStyle(selectedSlot == slot ? .white : MedNexTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MedNexTheme.Spacing.sm)
                            .background(
                                selectedSlot == slot ? AnyShapeStyle(MedNexTheme.Colors.primary) : AnyShapeStyle(MedNexTheme.Colors.elevatedBackground),
                                in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm)
                            )
                    }
                }
            }
            
            // Appointment type
            Picker("Type", selection: $appointmentType) {
                ForEach(AppointmentType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            // Confirm
            Button {
                HapticManager.success()
                if let doctor = selectedDoctor, let slot = selectedSlot {
                    dataStore.bookAppointment(
                        doctor: doctor,
                        date: selectedDate,
                        time: slot,
                        type: appointmentType
                    )
                }
                showConfirmation = true
            } label: {
                Text("Confirm Booking")
            }
            .buttonStyle(.medNexPrimary)
            .disabled(selectedSlot == nil)
            .opacity(selectedSlot != nil ? 1 : 0.6)
            .padding(.top, MedNexTheme.Spacing.sm)
        }
    }
    
    // MARK: - Step 4: Confirmation
    private var confirmationStep: some View {
        EmptyStateView(
            icon: "checkmark.circle.fill",
            title: "Booking Confirmed",
            message: "Your appointment has been scheduled.",
            actionTitle: "Done"
        ) { dismiss() }
    }
}
