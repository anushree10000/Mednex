//
//  AppointmentBookingView.swift
//  
//

import SwiftUI

// MARK: - iOS 26 Design Tokens
private enum Token {
    // Spacing
    static let xs:   CGFloat = 4
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let base: CGFloat = 16
    static let lg:   CGFloat = 20
    static let xl:   CGFloat = 24
    static let xxl:  CGFloat = 32

    // Radii
    static let pill:  CGFloat = 999
    static let card:  CGFloat = 20
    static let chip:  CGFloat = 12
    static let slot:  CGFloat = 14
}

// MARK: - Liquid Glass Card (iOS 26 style)
private struct LiquidCard<Content: View>: View {
    var padding: CGFloat = Token.base
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Token.card, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

// MARK: - Slot Button
private struct SlotButton: View {
    let title: String
    let subtitle: String?
    let state: SlotState

    enum SlotState { case available, selected, booked, blocked, past }

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .opacity(0.75)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Token.md)
        .foregroundStyle(foreground)
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: Token.slot, style: .continuous))
        .overlay {
            if state == .blocked || state == .booked || state == .past {
                RoundedRectangle(cornerRadius: Token.slot, style: .continuous)
                    .strokeBorder(
                        state == .blocked ? Color.red.opacity(0.35) : Color.secondary.opacity(0.25),
                        lineWidth: 1
                    )
            }
        }
    }

    private var backgroundStyle: AnyShapeStyle {
        switch state {
        case .selected:
            return AnyShapeStyle(MedNexTheme.Colors.primary)
        case .booked, .blocked, .past:
            return AnyShapeStyle(Color(uiColor: .tertiarySystemFill))
        case .available:
            return AnyShapeStyle(Color(uiColor: .secondarySystemFill))
        }
    }

    private var foreground: Color {
        switch state {
        case .selected:  .white
        case .booked, .blocked: .secondary
        case .past: Color.secondary.opacity(0.5)
        case .available: .primary
        }
    }
}

// MARK: - Doctor Row Card
private struct DoctorRowCard: View {
    let doctor: Doctor
    let hasActiveAppointment: Bool

    var body: some View {
        LiquidCard {
            HStack(spacing: Token.base) {
                // Avatar
                AvatarView(
                    name: doctor.name,
                    imageURL: doctor.profileImageURL,
                    size: 56,
                    backgroundColor: MedNexTheme.Colors.doctorTint
                )
                .overlay(
                    Circle().strokeBorder(Color(uiColor: .separator), lineWidth: 0.5)
                )

                VStack(alignment: .leading, spacing: Token.xs) {
                    Text(doctor.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(doctor.specialty.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(MedNexTheme.Colors.primary)

                    HStack(spacing: Token.sm) {
                        Label("\(doctor.experience) yrs", systemImage: "briefcase.fill")
                        Label(String(format: "%.1f", doctor.rating), systemImage: "star.fill")
                            .foregroundStyle(Color(uiColor: .systemOrange))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Token.xs) {
                    Text("₹\(Int(doctor.consultationFee))")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(MedNexTheme.Colors.primary)

                    if hasActiveAppointment {
                        Label("Active", systemImage: "clock.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .systemOrange))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color(uiColor: .systemOrange).opacity(0.15), in: Capsule())
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                }
            }
        }
    }
}

// MARK: - Specialty Filter Sheet
private struct SpecialtyFilterSheet: View {
    @Binding var selectedSpecialty: MedicalSpecialty?
    @Environment(\.dismiss) private var dismiss

    private let specialties = Array(MedicalSpecialty.allCases.prefix(12))

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Token.sm) {
                    // All Specialties option
                    Button {
                        HapticManager.selection()
                        selectedSpecialty = nil
                        dismiss()
                    } label: {
                        HStack(spacing: Token.md) {
                            ZStack {
                                Circle()
                                    .fill(selectedSpecialty == nil ? MedNexTheme.Colors.primary : Color(uiColor: .secondarySystemFill))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "stethoscope")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(selectedSpecialty == nil ? .white : MedNexTheme.Colors.primary)
                            }
                            Text("All Specialties")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedSpecialty == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(MedNexTheme.Colors.primary)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(Token.md)
                        .background(
                            selectedSpecialty == nil
                                ? AnyShapeStyle(MedNexTheme.Colors.primary.opacity(0.08))
                                : AnyShapeStyle(Color(uiColor: .secondarySystemGroupedBackground)),
                            in: RoundedRectangle(cornerRadius: Token.card, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)

                    ForEach(specialties) { specialty in
                        Button {
                            HapticManager.selection()
                            selectedSpecialty = specialty
                            dismiss()
                        } label: {
                            HStack(spacing: Token.md) {
                                ZStack {
                                    Circle()
                                        .fill(selectedSpecialty == specialty ? MedNexTheme.Colors.primary : Color(uiColor: .secondarySystemFill))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: specialty.icon)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(selectedSpecialty == specialty ? .white : MedNexTheme.Colors.primary)
                                }
                                Text(specialty.rawValue)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedSpecialty == specialty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(MedNexTheme.Colors.primary)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(Token.md)
                            .background(
                                selectedSpecialty == specialty
                                    ? AnyShapeStyle(MedNexTheme.Colors.primary.opacity(0.08))
                                    : AnyShapeStyle(Color(uiColor: .secondarySystemGroupedBackground)),
                                in: RoundedRectangle(cornerRadius: Token.card, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Token.base)
                .padding(.bottom, Token.xxl)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Filter by Specialty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .fontWeight(.medium)
                }
                if selectedSpecialty != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Clear") {
                            selectedSpecialty = nil
                            dismiss()
                        }
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Main View
struct AppointmentBookingView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore

    // Navigation — Step 0: Doctors, Step 1: Date & Time, Step 2: Quick Book
    @State private var step = 0

    // Selections
    @State private var selectedSpecialty: MedicalSpecialty?
    @State private var selectedDoctor: Doctor?
    @State private var selectedDate = Date()
    @State private var selectedSlot: String?

    // UI state
    @State private var searchText = ""
    @State private var symptoms = ""
    @State private var showDoctorProfile = false
    @State private var showConfirmation = false
    @State private var showAdmittedAlert = false
    @State private var showActiveAppointmentAlert = false
    @State private var showFilterSheet = false
    @State private var showSlotConflict = false
    @State private var showDoctorUnavailable = false
    @State private var showPaymentGate = false
    @State private var pendingQuickBookDoctor: Doctor?
    @State private var pendingQuickBookDate: Date?
    @State private var pendingQuickBookSlot: String?
    @State private var isBooking = false

    // Slot availability
    @State private var bookedSlots: Set<String> = []
    @State private var blockedSlots: Set<String> = []
    @State private var isLoadingSlots = false
    @State private var quickBookSlots: [String: (date: Date, time: String)] = [:]

    @State private var showAISuggestions = true
    @State private var aiSuggestedSlots: [AISuggestedSlot] = []
    
    
    private var doctors: [Doctor] { dataStore.doctors }
    private let timeSlots = [
        "9:00 AM", "9:30 AM", "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM",
        "2:00 PM", "2:30 PM", "3:00 PM", "3:30 PM", "4:00 PM", "4:30 PM"
    ]

    // MARK: - Computed helpers
    private var isPatientAdmitted: Bool {
        dataStore.admissions.contains { $0.patientId == dataStore.patient.id && $0.status == .admitted }
    }

    private var maxBookingDate: Date {
        Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    }

    private func hasActiveAppointmentWith(_ doctor: Doctor) -> Bool {
        let id = doctor.userId.isEmpty ? doctor.id : doctor.userId
        return dataStore.appointments.contains {
            $0.patientId == dataStore.patient.id && $0.doctorId == id &&
            ($0.status == .scheduled || $0.status == .inProgress)
        }
    }

    var filteredDoctors: [Doctor] {
        var result = doctors.filter { $0.isAvailable }
        if let s = selectedSpecialty { result = result.filter { $0.specialty == s } }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.specialty.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    private var availableTimeSlots: [String] {
        return timeSlots
    }

    private func slotState(_ slot: String) -> SlotButton.SlotState {
        if Calendar.current.isDateInToday(selectedDate) && slot.isPastTimeToday { return .past }
        if selectedSlot == slot { return .selected }
        if blockedSlots.contains(slot) { return .blocked }
        if bookedSlots.contains(slot) { return .booked }
        return .available
    }

    // MARK: - Body
    
    /// Whether a slot is unavailable (booked by another patient OR blocked by the doctor OR past time today)
    private func isSlotUnavailable(_ slot: String) -> Bool {
        slotState(slot) != .available && slotState(slot) != .selected
    }
    
    /// Label for unavailable slot
    private func unavailableLabel(_ slot: String) -> String {
        if blockedSlots.contains(slot) { return "Blocked" }
        if bookedSlots.contains(slot) { return "Booked" }
        return ""
    }
    
    // MARK: - Load Booked + Blocked Slots from Supabase
    private func loadBookedSlots() {
        guard let doctor = selectedDoctor else { bookedSlots = []; blockedSlots = []; return }
        let doctorId = doctor.userId.isEmpty ? doctor.id : doctor.userId
        let date = selectedDate
        isLoadingSlots = true
        Task {
            async let booked = dataStore.fetchBookedSlots(doctorId: doctorId, date: date)
            async let blocked = dataStore.fetchBlockedSlots(doctorId: doctorId, date: date)
            let (b, bl) = await (booked, blocked)
            await MainActor.run {
                bookedSlots = b
                blockedSlots = bl
                isLoadingSlots = false
                computeAISuggestions()
            }
        }
    }
    
    // MARK: - H0-48: AI Appointment Suggestion Engine
    //
    // Uses REAL backend data only:
    // - dataStore.appointments (existing bookings for this doctor)
    // - bookedSlots / blockedSlots (fetched from Supabase)
    // - timeSlots (the 12 available clinic slots)
    //
    // Scoring algorithm:
    //   +3  slot is tomorrow or day-after (sooner = better for patient)
    //   +2  morning slot (9-11 AM) if doctor has fewer morning bookings historically
    //   +2  afternoon slot (2-4 PM) if doctor has fewer afternoon bookings
    //   +1  slot adjacent to an existing booking (efficient for doctor schedule)
    //   -10 slot is booked or blocked (excluded)
    //   -10 slot is in the past
    
    private func computeAISuggestions() {
        guard let doctor = selectedDoctor else { aiSuggestedSlots = []; return }
        let doctorId = doctor.userId.isEmpty ? doctor.id : doctor.userId
        let calendar = Calendar.current
        
        // Analyze doctor's historical booking patterns for morning vs afternoon preference
        let doctorAppts = dataStore.appointments.filter { $0.doctorId == doctorId && $0.status != .cancelled }
        let morningAppts = doctorAppts.filter { calendar.component(.hour, from: $0.dateTime) < 12 }.count
        let afternoonAppts = doctorAppts.filter { calendar.component(.hour, from: $0.dateTime) >= 12 }.count
        let preferMorning = morningAppts <= afternoonAppts // suggest the lighter period
        
        // Get booked slot times on the selected date for adjacency scoring
        let bookedTimes = bookedSlots
        
        var scored: [AISuggestedSlot] = []
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        
        // Score slots on the currently selected date
        let isToday = calendar.isDateInToday(selectedDate)
        let isTomorrow = calendar.isDateInTomorrow(selectedDate)
        let dayOffset = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: selectedDate)).day ?? 0
        
        for slot in timeSlots {
            var score = 0
            
            // Exclude booked/blocked
            if bookedTimes.contains(slot) || blockedSlots.contains(slot) { continue }
            
            // Exclude past slots on today
            if isToday && slot.isPastTimeToday { continue }
            
            // Proximity bonus: sooner dates score higher
            if isTomorrow || dayOffset == 0 { score += 3 }
            else if dayOffset <= 3 { score += 2 }
            else if dayOffset <= 7 { score += 1 }
            
            // Time-of-day preference (suggest the lighter period)
            if let slotTime = formatter.date(from: slot) {
                let hour = calendar.component(.hour, from: slotTime)
                if hour < 12 && preferMorning { score += 2 }
                if hour >= 12 && !preferMorning { score += 2 }
            }
            
            // Adjacency bonus: slot next to an existing booking = efficient schedule
            if let slotIdx = timeSlots.firstIndex(of: slot) {
                let prevSlot = slotIdx > 0 ? timeSlots[slotIdx - 1] : nil
                let nextSlot = slotIdx < timeSlots.count - 1 ? timeSlots[slotIdx + 1] : nil
                if let prev = prevSlot, bookedTimes.contains(prev) { score += 1 }
                if let next = nextSlot, bookedTimes.contains(next) { score += 1 }
            }
            
            scored.append(AISuggestedSlot(date: selectedDate, time: slot, score: score))
        }
        
        // Return top 3
        aiSuggestedSlots = Array(scored.sorted { $0.score > $1.score }.prefix(3))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Token.xl) {
                    switch step {
                    case 0: doctorStep
                    case 1: dateTimeStep
                    case 2: quickBookStep
                    default: doneStep
                    }
                }
                .padding(.horizontal, Token.base)
                .padding(.bottom, Token.xxl * 2)
            }
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if step == 2 {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) { step = 0 }
                        } label: {
                            Label("Doctors", systemImage: "chevron.left")
                        }
                        .fontWeight(.medium)
                    } else {
                        Button("Cancel") { dismiss() }
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .alert("Appointment Booked!", isPresented: $showConfirmation) {
            Button("Done", role: .cancel) { dismiss() }
        } message: {
            Text("Confirmed with \(selectedDoctor?.name ?? "") on \(selectedDate.shortDate) at \(selectedSlot ?? "").")
        }
        .alert("Cannot Book", isPresented: $showAdmittedAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("You are currently admitted. Please contact your attending physician for scheduling.")
        }
        .alert("Active Appointment", isPresented: $showActiveAppointmentAlert) {
            Button("OK") { }
        } message: {
            Text("You already have an active appointment with \(selectedDoctor?.name ?? "this doctor").")
        }
        .alert("Slot No Longer Available", isPresented: $showSlotConflict) {
            Button("OK") { }
        } message: {
            Text("This time slot was just booked or blocked by the doctor. The available slots have been refreshed — please select another time.")
        }
        .alert("Doctor No Longer Available", isPresented: $showDoctorUnavailable) {
            Button("OK") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                    selectedDoctor = nil
                    selectedSlot = nil
                    step = 0
                }
            }
        } message: {
            Text("\(selectedDoctor?.name ?? "This doctor") is no longer accepting appointments. Please choose another doctor.")
        }
        .sheet(isPresented: $showDoctorProfile) {
            if let doc = selectedDoctor {
                DoctorProfileDetailView(doctor: doc) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { step = 1 }
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            SpecialtyFilterSheet(selectedSpecialty: $selectedSpecialty)
        }
        .sheet(isPresented: $showPaymentGate) {
            PaymentGateView(
                title: "Appointment Fee",
                description: step == 2
                    ? "Consultation with \(pendingQuickBookDoctor?.name ?? "Doctor")"
                    : "Consultation with \(selectedDoctor?.name ?? "Doctor")",
                amount: PricingConfig.price(for: .consultation),
                patientEmail: "\(dataStore.patient.id)@mednex.hospital",
                referenceId: UUID().uuidString,
                onPaymentComplete: { mode in
                    let docName = step == 2 ? pendingQuickBookDoctor?.name : selectedDoctor?.name
                    
                    if step == 2, let qDoc = pendingQuickBookDoctor {
                        // Quick Book path
                        selectedDoctor = qDoc
                        selectedDate = pendingQuickBookDate ?? Date()
                        selectedSlot = pendingQuickBookSlot
                        pendingQuickBookDoctor = nil
                        pendingQuickBookDate = nil
                        pendingQuickBookSlot = nil
                    }
                    
                    if let newAppt = confirmBooking() {
                        let doctorName = docName ?? "Doctor"
                        let consultingFee = PricingConfig.price(for: .consultation)
                        
                        let billItems = [
                            BillItem(
                                description: "Consultation with \(doctorName)",
                                quantity: 1,
                                unitPrice: Double(consultingFee),
                                total: Double(consultingFee),
                                category: .consultation
                            )
                        ]
                        
                        let pb = dataStore.patient
                        _ = dataStore.createPaidBill(
                            appointmentId: newAppt.id,
                            patientId: pb.id,
                            patientName: pb.personalInfo.fullName,
                            items: billItems,
                            paymentMode: mode
                        )
                    }
                    
                    showConfirmation = true
                },
                onCancel: { }
            )
        }
        .onAppear { if isPatientAdmitted { showAdmittedAlert = true } }
        .onChange(of: selectedDoctor?.id) { _, _ in loadBookedSlots() }
        .onChange(of: selectedDate) { _, _ in loadBookedSlots() }
        // Realtime: when appointments change (doctor blocks/books), refresh slot grid
        .onChange(of: dataStore.appointments.count) { _, _ in
            if step == 1, selectedDoctor != nil {
                loadBookedSlots()
            }
        }
        // Realtime: when doctor availability changes, check if selected doctor went unavailable
        .onChange(of: dataStore.doctors.map(\.isAvailable)) { _, _ in
            if step == 1, let doc = selectedDoctor {
                let freshDoc = dataStore.doctors.first(where: { $0.id == doc.id })
                if freshDoc?.isAvailable == false {
                    showDoctorUnavailable = true
                }
            }
        }
    }

    private var navigationTitle: String {
        switch step {
        case 0: return "Find a Doctor"
        case 1: return "Date & Time"
        case 2: return "Quick Book"
        default: return "Confirmed"
        }
    }

    // MARK: - Step 0: Doctors (primary step)
    private var doctorStep: some View {
        VStack(alignment: .leading, spacing: Token.lg) {

            // Quick Book CTA — prominent top card
            Button {
                HapticManager.selection()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) { step = 2 }
            } label: {
                LiquidCard {
                    HStack(spacing: Token.md) {
                        ZStack {
                            Circle()
                                .fill(MedNexTheme.Colors.primary.opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(MedNexTheme.Colors.primary)
                                .symbolEffect(.pulse)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quick Book")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("Next available slot — any doctor")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                }
            }
            .buttonStyle(.plain)

            // Section header
            SectionHeader(title: "All Doctors")

            // Search bar with filter button
            HStack(spacing: Token.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 15))
                TextField("Search doctors…", text: $searchText)
                    .font(.system(size: 15))
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                }
                // Filter button
                Button {
                    HapticManager.selection()
                    showFilterSheet = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(selectedSpecialty != nil ? MedNexTheme.Colors.primary : Color(uiColor: .tertiaryLabel))
                            .symbolEffect(.bounce, value: selectedSpecialty != nil)

                        // Active filter dot
                        if selectedSpecialty != nil {
                            Circle()
                                .fill(MedNexTheme.Colors.primary)
                                .frame(width: 8, height: 8)
                                .offset(x: 1, y: -1)
                        }
                    }
                }
            }
            .padding(.horizontal, Token.md)
            .padding(.vertical, Token.md)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Token.chip, style: .continuous))

            // Active filter chip
            if let specialty = selectedSpecialty {
                HStack(spacing: Token.sm) {
                    Image(systemName: specialty.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MedNexTheme.Colors.primary)
                    Text(specialty.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MedNexTheme.Colors.primary)
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedSpecialty = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(MedNexTheme.Colors.primary.opacity(0.6))
                    }
                }
                .padding(.horizontal, Token.md)
                .padding(.vertical, Token.sm)
                .background(MedNexTheme.Colors.primary.opacity(0.1), in: Capsule())
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }

            // Doctor list
            if filteredDoctors.isEmpty {
                LiquidCard {
                    VStack(spacing: Token.md) {
                        Image(systemName: "stethoscope")
                            .font(.largeTitle)
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        Text("No doctors found")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                        if selectedSpecialty != nil {
                            Text("Try clearing the specialty filter")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Token.xxl)
                }
            } else {
                VStack(spacing: Token.sm) {
                    ForEach(filteredDoctors) { doctor in
                        Button {
                            HapticManager.selection()
                            selectedDoctor = doctor
                            if hasActiveAppointmentWith(doctor) {
                                showActiveAppointmentAlert = true
                            } else {
                                showDoctorProfile = true
                            }
                        } label: {
                            DoctorRowCard(doctor: doctor, hasActiveAppointment: hasActiveAppointmentWith(doctor))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.top, Token.xs)
    }

    // MARK: - Step 1: Date + Time
    private var dateTimeStep: some View {
        VStack(alignment: .leading, spacing: Token.lg) {
            BackButton(label: "Doctors") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) { step = 0 }
            }

            // Selected doctor summary chip
            if let doc = selectedDoctor {
                LiquidCard(padding: Token.md) {
                    HStack(spacing: Token.md) {
                        AvatarView(name: doc.name, imageURL: doc.profileImageURL, size: 40, backgroundColor: MedNexTheme.Colors.doctorTint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(doc.name)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Text(doc.specialty.rawValue)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("₹\(Int(doc.consultationFee))")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(MedNexTheme.Colors.primary)
                    }
                }
            }

            SectionHeader(title: "Pick a Date")

            // Calendar — native graphical style
            LiquidCard {
                DatePicker(
                    "Date",
                    selection: $selectedDate,
                    in: Date()...maxBookingDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(MedNexTheme.Colors.primary)
                .onChange(of: selectedDate) { _, _ in
                    selectedSlot = nil
                    loadBookedSlots()
                }
            }

            // Time slots
            SectionHeader(title: "Available Times")

            
            Text("Available Slots")
                .font(MedNexTheme.Typography.headline)
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
            
            // MARK: H0-48 — AI Suggested Slots
            if !aiSuggestedSlots.isEmpty && !isLoadingSlots {
                GlassCard(padding: MedNexTheme.Spacing.sm) {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                        Button {
                            withAnimation(MedNexTheme.Animation.smooth) {
                                showAISuggestions.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.yellow)
                                Text("Suggested for You")
                                    .font(MedNexTheme.Typography.subheadline.weight(.semibold))
                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: showAISuggestions ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if showAISuggestions {
                            Text("Based on doctor availability and schedule patterns")
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            
                            HStack(spacing: MedNexTheme.Spacing.sm) {
                                ForEach(aiSuggestedSlots) { suggestion in
                                    Button {
                                        HapticManager.selection()
                                        selectedSlot = suggestion.time
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: "sparkle")
                                                .font(.caption2)
                                                .foregroundStyle(.yellow)
                                            Text(suggestion.time)
                                                .font(MedNexTheme.Typography.subheadline.weight(.medium))
                                        }
                                        .foregroundStyle(
                                            selectedSlot == suggestion.time ? .white : MedNexTheme.Colors.primary
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, MedNexTheme.Spacing.sm)
                                        .background(
                                            selectedSlot == suggestion.time
                                            ? AnyShapeStyle(MedNexTheme.Colors.primary)
                                            : AnyShapeStyle(MedNexTheme.Colors.primary.opacity(0.1)),
                                            in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Suggested slot: \(suggestion.time)")
                                }
                            }
                        }
                    }
                }
            }
            
            if isLoadingSlots {
                LiquidCard {
                    HStack(spacing: Token.sm) {
                        ProgressView()
                        Text("Loading slots…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Token.xl)
                }
            } else if availableTimeSlots.isEmpty {
                LiquidCard {
                    Label("No slots today — pick a future date.", systemImage: "clock.badge.exclamationmark")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Token.xl)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: Token.sm), count: 3),
                    spacing: Token.sm
                ) {
                    ForEach(timeSlots, id: \.self) { slot in
                        let state = slotState(slot)
                        let isUnavailable = isSlotUnavailable(slot)

                        Button {
                            guard !isUnavailable else { return }
                            HapticManager.selection()
                            withAnimation(.spring(response: 0.3)) { selectedSlot = slot }
                        } label: {
                            SlotButton(
                                title: slot,
                                subtitle: isUnavailable ? (state == .blocked ? "Blocked" : (state == .booked ? "Booked" : "Passed")) : nil,
                                state: state
                            )
                        }
                        .disabled(isUnavailable)
                    }
                }
            }

            // Confirm CTA — with last-second slot guard → payment gate
            Button {
                guard !isBooking else { return }
                isBooking = true
                Task {
                    let slotStillFree = await verifySlotAvailable()
                    await MainActor.run {
                        isBooking = false
                        if slotStillFree {
                            HapticManager.selection()
                            showPaymentGate = true
                        } else {
                            HapticManager.error()
                            showSlotConflict = true
                            loadBookedSlots()
                            selectedSlot = nil
                        }
                    }
                }
            } label: {
                HStack {
                    if isBooking {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "indianrupeesign.circle.fill")
                        Text("Pay \(PricingConfig.formatted(PricingConfig.price(for: .consultation))) & Book")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Token.base)
                .background(selectedSlot != nil ? MedNexTheme.Colors.primary : Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: Token.card, style: .continuous))
                .foregroundStyle(selectedSlot != nil ? .white : Color(uiColor: .tertiaryLabel))
            }
            .disabled(selectedSlot == nil || isBooking)
            .animation(.easeInOut(duration: 0.2), value: selectedSlot)
            .padding(.top, Token.sm)
        }
    }

    // MARK: - Step 2: Quick Book
    private var quickBookStep: some View {
        VStack(alignment: .leading, spacing: Token.lg) {

            VStack(alignment: .leading, spacing: 2) {
                Text("Next Available")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Tap to instantly book")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            if filteredDoctors.isEmpty {
                LiquidCard {
                    Label("No doctors available", systemImage: "stethoscope")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Token.xxl)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: Token.sm) {
                    // Sort by soonest available slot (doctors with earlier slots first)
                    let sortedDoctors = filteredDoctors.sorted { a, b in
                        let slotA = quickBookSlots[a.id]
                        let slotB = quickBookSlots[b.id]
                        guard let dA = slotA?.date, let dB = slotB?.date else { return slotA != nil }
                        if !Calendar.current.isDate(dA, inSameDayAs: dB) { return dA < dB }
                        let idxA = timeSlots.firstIndex(of: slotA?.time ?? "") ?? timeSlots.count
                        let idxB = timeSlots.firstIndex(of: slotB?.time ?? "") ?? timeSlots.count
                        return idxA < idxB
                    }
                    ForEach(sortedDoctors) { doctor in
                        let cachedSlot = quickBookSlots[doctor.id]

                        Button {
                            if hasActiveAppointmentWith(doctor) {
                                selectedDoctor = doctor
                                showActiveAppointmentAlert = true
                                return
                            }
                            HapticManager.success()
                            Task {
                                let next = await nextAvailableSlot(for: doctor)
                                // Last-second re-check for quick book
                                let id = doctor.userId.isEmpty ? doctor.id : doctor.userId
                                let freshBooked = await dataStore.fetchBookedSlots(doctorId: id, date: next.date)
                                let freshBlocked = await dataStore.fetchBlockedSlots(doctorId: id, date: next.date)
                                await MainActor.run {
                                    selectedDoctor = doctor
                                    selectedDate = next.date
                                    selectedSlot = next.time
                                    if freshBooked.contains(next.time) || freshBlocked.contains(next.time) {
                                        HapticManager.error()
                                        showSlotConflict = true
                                        selectedSlot = nil
                                    } else {
                                        pendingQuickBookDoctor = doctor
                                        pendingQuickBookDate = next.date
                                        pendingQuickBookSlot = next.time
                                        showPaymentGate = true
                                    }
                                }
                            }
                        } label: {
                            LiquidCard {
                                HStack(spacing: Token.md) {
                                    AvatarView(name: doctor.name, imageURL: doctor.profileImageURL, size: 52, backgroundColor: MedNexTheme.Colors.doctorTint)

                                    VStack(alignment: .leading, spacing: Token.xs) {
                                        Text(doctor.name)
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.primary)
                                        Text(doctor.specialty.rawValue)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                        HStack(spacing: Token.sm) {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(Color(uiColor: .systemOrange))
                                            Text(String(format: "%.1f", doctor.rating))
                                            Text("·")
                                            Text("\(doctor.experience) yrs")
                                        }
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: Token.xs) {
                                        Text("₹\(Int(doctor.consultationFee))")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(MedNexTheme.Colors.primary)

                                        if let slot = cachedSlot {
                                            VStack(alignment: .trailing, spacing: 1) {
                                                Text(slot.date.shortDate)
                                                    .font(.system(size: 11, weight: .semibold))
                                                Text(slot.time)
                                                    .font(.system(size: 10))
                                            }
                                            .foregroundStyle(Color(uiColor: .systemGreen))
                                        } else {
                                            ProgressView().controlSize(.small)
                                        }
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .task {
            for doctor in doctors {
                let slot = await nextAvailableSlot(for: doctor)
                await MainActor.run { quickBookSlots[doctor.id] = slot }
            }
        }
    }

    // MARK: - Done step
    private var doneStep: some View {
        EmptyStateView(
            icon: "checkmark.circle.fill",
            title: "Booking Confirmed",
            message: "Your appointment has been scheduled.",
            actionTitle: "Done"
        ) { dismiss() }
    }

    // MARK: - Helpers
  

    private func confirmBooking() -> Appointment? {
        guard let doctor = selectedDoctor, let slot = selectedSlot else { return nil }
        let name = resolvedPatientName()
        let dt = combinedDateTime(from: selectedDate, slot: slot)
        return dataStore.bookAppointment(
            patientId: dataStore.patient.id,
            patientName: name,
            doctorId: doctor.userId.isEmpty ? doctor.id : doctor.userId,
            doctorName: doctor.name,
            specialty: doctor.specialty,
            dateTime: dt,
            type: .consultation,
            notes: symptoms.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    /// Last-second slot availability check — re-fetches from Supabase to prevent double booking
    private func verifySlotAvailable() async -> Bool {
        guard let doctor = selectedDoctor, let slot = selectedSlot else { return false }
        // Check doctor is still available
        let freshDoctor = await MainActor.run { dataStore.doctors.first(where: { $0.id == doctor.id }) }
        if freshDoctor?.isAvailable == false {
            await MainActor.run { showDoctorUnavailable = true }
            return false
        }
        let doctorId = doctor.userId.isEmpty ? doctor.id : doctor.userId
        async let freshBooked = dataStore.fetchBookedSlots(doctorId: doctorId, date: selectedDate)
        async let freshBlocked = dataStore.fetchBlockedSlots(doctorId: doctorId, date: selectedDate)
        let (booked, blocked) = await (freshBooked, freshBlocked)
        return !booked.contains(slot) && !blocked.contains(slot)
    }

    private func nextAvailableSlot(for doctor: Doctor) async -> (date: Date, time: String) {
        let calendar = Calendar.current
        let id = doctor.userId.isEmpty ? doctor.id : doctor.userId
        for offset in 0...14 {
            let isToday = offset == 0
            guard let date = calendar.date(byAdding: .day, value: offset, to: Date()) else { continue }
            let booked = await dataStore.fetchBookedSlots(doctorId: id, date: date)
            let blocked = await dataStore.fetchBlockedSlots(doctorId: id, date: date)
            if let free = timeSlots.first(where: { 
                !booked.contains($0) && !blocked.contains($0) && !(isToday && $0.isPastTimeToday)
            }) { 
                return (date, free) 
            }
        }
        let fallback = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return (fallback, timeSlots[0])
    }

    private func resolvedPatientName() -> String {
        let p = dataStore.patient.personalInfo.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !p.isEmpty { return p }
        let a = (appState.currentUser?.displayName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return a.isEmpty ? "Unknown Patient" : a
    }

    private func combinedDateTime(from date: Date, slot: String) -> Date {
        let fmt = DateFormatter(); fmt.locale = Locale(identifier: "en_US_POSIX"); fmt.dateFormat = "h:mm a"
        guard let t = fmt.date(from: slot) else { return date }
        let cal = Calendar.current
        let dc = cal.dateComponents([.year, .month, .day], from: date)
        let tc = cal.dateComponents([.hour, .minute], from: t)
        var c = DateComponents()
        c.year = dc.year; c.month = dc.month; c.day = dc.day
        c.hour = tc.hour; c.minute = tc.minute
        return cal.date(from: c) ?? date
    }
}

// MARK: - Small reusable helpers (scoped to this file)

private struct BackButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: "chevron.left")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(MedNexTheme.Colors.primary)
        }
    }
}

// MARK: - AI Suggestion Model

struct AISuggestedSlot: Identifiable {
    let date: Date
    let time: String
    let score: Int
    
    var id: String { "\(date.timeIntervalSince1970)-\(time)" }
}
