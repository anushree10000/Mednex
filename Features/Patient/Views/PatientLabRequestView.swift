import SwiftUI

private enum LRT {
    static let xs:   CGFloat = 4
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let base: CGFloat = 16
    static let lg:   CGFloat = 20
    static let xl:   CGFloat = 24
    static let xxl:  CGFloat = 32
    static let card: CGFloat = 20
    static let chip: CGFloat = 12
}

private struct LiquidCard<Content: View>: View {
    var padding: CGFloat = LRT.base
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: LRT.card, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

private struct CategoryChip: View {
    let category: PatientLabCategory
    let isSelected: Bool

    var body: some View {
        HStack(spacing: LRT.sm) {
            Image(systemName: category.icon)
                .font(.system(size: 14, weight: .semibold))
                .symbolEffect(.bounce, value: isSelected)
            Text(category.displayName)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(isSelected ? .white : .primary)
        .padding(.horizontal, LRT.base)
        .padding(.vertical, LRT.md)
        .background(
            isSelected
                ? AnyShapeStyle(MedNexTheme.Colors.primary)
                : AnyShapeStyle(Color(uiColor: .secondarySystemFill)),
            in: Capsule()
        )
        .contentShape(Capsule())
    }
}

private struct TestRow: View {
    let name: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: LRT.md) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isSelected ? MedNexTheme.Colors.primary : Color(uiColor: .tertiaryLabel))
                .symbolEffect(.bounce, value: isSelected)
                .contentTransition(.symbolEffect(.replace))

            Text(name)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.vertical, LRT.sm)
        .contentShape(Rectangle())
    }
}

struct PatientLabRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @State private var selectedCategory = PatientLabCategory.bloodWork
    @State private var selectedTests: Set<String> = []
    @State private var preferredDate = Date().addingTimeInterval(86400)
    @State private var notes = ""
    @State private var doctorReferral = ""
    @State private var showConfirmation = false
    @State private var showPaymentGate = false
    @State private var appearAnimations: [Int: Bool] = [:]
    @State private var isTestSectionExpanded = true

    private var isAdmitted: Bool {
        dataStore.admissions.contains { $0.patientId == dataStore.patient.id && $0.status == .admitted }
    }

    private var canSubmit: Bool {
        !selectedTests.isEmpty && !isAdmitted
    }

    private var selectedTestsInCurrentCategory: Int {
        selectedCategory.availableTests.filter { selectedTests.contains($0) }.count
    }

    private var totalLabAmount: Int {
        PricingConfig.totalLabPrice(testCount: selectedTests.count, category: selectedCategory.labTestCategory)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: LRT.xl) {
                if isAdmitted {
                    admissionWarning
                }

                categorySection
                    .sectionAppear(index: 0, animations: $appearAnimations)

                testSelectionSection
                    .sectionAppear(index: 1, animations: $appearAnimations)

                dateSection
                    .sectionAppear(index: 2, animations: $appearAnimations)

                referralSection
                    .sectionAppear(index: 3, animations: $appearAnimations)

                notesSection
                    .sectionAppear(index: 4, animations: $appearAnimations)

                if !selectedTests.isEmpty {
                    summarySection
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .padding(.horizontal, LRT.base)
            .padding(.top, LRT.sm)
            .padding(.bottom, 100)
        }
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Book Lab Test")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            floatingSubmitButton
        }
        .onAppear { staggerAppear() }
        .onChange(of: selectedCategory) { _, _ in
            withAnimation(.spring(response: 0.3)) {
                isTestSectionExpanded = true
            }
        }
        .alert("Request Submitted!", isPresented: $showConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your lab test request for \(selectedTests.count) test(s) has been submitted. You'll receive a confirmation with your appointment slot.")
        }
        .sheet(isPresented: $showPaymentGate) {
            PaymentGateView(
                title: "Lab Test Fee",
                description: "\(selectedTests.count) test(s) — \(selectedCategory.displayName)",
                amount: totalLabAmount,
                itemBreakdown: selectedTests.map { name in
                    (name: name, price: PricingConfig.price(for: selectedCategory.labTestCategory))
                },
                patientEmail: "\(dataStore.patient.id)@mednex.hospital",
                referenceId: UUID().uuidString,
                onPaymentComplete: { mode in
                    let patient = dataStore.patient
                    for testName in selectedTests {
                        _ = dataStore.orderLabTest(
                            patientId: patient.id,
                            patientName: patient.personalInfo.fullName,
                            doctorId: doctorReferral.isEmpty ? "self-request" : UUID().uuidString,
                            doctorName: doctorReferral.isEmpty ? "Self-Requested" : doctorReferral,
                            testName: testName,
                            testCategory: selectedCategory.labTestCategory,
                            notes: notes
                        )
                    }
                    
                    let testPrice = Double(PricingConfig.price(for: selectedCategory.labTestCategory))
                    let billItems = selectedTests.map { testName in
                        BillItem(
                            description: "\(testName) - \(selectedCategory.displayName)",
                            quantity: 1,
                            unitPrice: testPrice,
                            total: testPrice,
                            category: .labTest
                        )
                    }
                    
                    _ = dataStore.createPaidBill(
                        appointmentId: "",
                        patientId: patient.id,
                        patientName: patient.personalInfo.fullName,
                        items: billItems,
                        paymentMode: mode
                    )
                    
                    showConfirmation = true
                },
                onCancel: { }
            )
        }
    }

    private var admissionWarning: some View {
        LiquidCard {
            HStack(spacing: LRT.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(MedNexTheme.Colors.warning)

                VStack(alignment: .leading, spacing: LRT.xs) {
                    Text("Lab Tests Unavailable")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("You are currently admitted as an inpatient. Lab tests are managed by your care team during admission.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: LRT.md) {
            SectionHeader(title: "Test Category")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LRT.sm) {
                    ForEach(PatientLabCategory.allCases) { category in
                        Button {
                            HapticManager.selection()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedCategory = category
                            }
                        } label: {
                            CategoryChip(category: category, isSelected: selectedCategory == category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var testSelectionSection: some View {
        LiquidCard {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isTestSectionExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "flask.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MedNexTheme.Colors.primary)

                        Text("Select Tests")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)

                        Spacer()

                        if !selectedTests.isEmpty {
                            Text("\(selectedTests.count) selected")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, LRT.md)
                                .padding(.vertical, LRT.xs)
                                .background(MedNexTheme.Colors.primary, in: Capsule())
                        }

                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                            .rotationEffect(.degrees(isTestSectionExpanded ? 0 : -90))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .padding(.top, LRT.md)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(selectedCategory.availableTests, id: \.self) { test in
                            Button {
                                HapticManager.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    if selectedTests.contains(test) {
                                        selectedTests.remove(test)
                                    } else {
                                        selectedTests.insert(test)
                                    }
                                }
                            } label: {
                                TestRow(name: test, isSelected: selectedTests.contains(test))
                            }
                            .buttonStyle(.plain)

                            if test != selectedCategory.availableTests.last {
                                Divider().opacity(0.5)
                            }
                        }
                    }
                    .padding(.top, LRT.sm)
                }
                .frame(maxHeight: isTestSectionExpanded ? .infinity : 0)
                .clipped()
                .opacity(isTestSectionExpanded ? 1 : 0)
            }
        }
    }

    private var dateSection: some View {
        LiquidCard {
            VStack(alignment: .leading, spacing: LRT.md) {
                HStack(spacing: LRT.sm) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MedNexTheme.Colors.primary)
                    Text("Preferred Date")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                DatePicker("Date", selection: $preferredDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .tint(MedNexTheme.Colors.primary)
            }
        }
    }

    private var referralSection: some View {
        LiquidCard {
            VStack(alignment: .leading, spacing: LRT.md) {
                HStack(spacing: LRT.sm) {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MedNexTheme.Colors.primary)
                    Text("Doctor Referral")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Optional")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        .padding(.horizontal, LRT.sm)
                        .padding(.vertical, LRT.xs)
                        .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
                }

                HStack(spacing: LRT.md) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        .font(.system(size: 15))
                    TextField("Doctor's name (if referred)", text: $doctorReferral)
                        .font(.system(size: 15))
                }
                .padding(LRT.md)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: LRT.chip, style: .continuous)
                )
            }
        }
    }

    private var notesSection: some View {
        LiquidCard {
            VStack(alignment: .leading, spacing: LRT.md) {
                HStack(spacing: LRT.sm) {
                    Image(systemName: "note.text")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MedNexTheme.Colors.primary)
                    Text("Additional Notes")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                TextField("Any symptoms or relevant information…", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .font(.system(size: 15))
                    .padding(LRT.md)
                    .background(
                        Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: LRT.chip, style: .continuous)
                    )
            }
        }
    }

    private var summarySection: some View {
        LiquidCard {
            VStack(alignment: .leading, spacing: LRT.md) {
                HStack(spacing: LRT.sm) {
                    Image(systemName: "list.clipboard")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MedNexTheme.Colors.primary)
                    Text("Request Summary")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Divider()

                summaryRow(icon: "flask.fill", label: "Tests", value: "\(selectedTests.count) test(s)")
                summaryRow(icon: "calendar", label: "Date", value: preferredDate.formatted(date: .abbreviated, time: .shortened))
                if !doctorReferral.trimmingCharacters(in: .whitespaces).isEmpty {
                    summaryRow(icon: "stethoscope", label: "Referral", value: doctorReferral)
                }
            }
        }
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: LRT.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(MedNexTheme.Colors.primary)
                .frame(width: 24, height: 24)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, LRT.xs)
    }

    private var floatingSubmitButton: some View {
        Button {
            HapticManager.selection()
            showPaymentGate = true
        } label: {
            HStack(spacing: LRT.sm) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                Text(canSubmit ? "Pay \(PricingConfig.formatted(totalLabAmount)) & Submit" : "Submit Lab Request")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LRT.base)
            .background(
                canSubmit
                    ? AnyShapeStyle(MedNexTheme.Colors.primary)
                    : AnyShapeStyle(Color(uiColor: .tertiarySystemFill)),
                in: RoundedRectangle(cornerRadius: LRT.card, style: .continuous)
            )
            .foregroundStyle(canSubmit ? .white : Color(uiColor: .tertiaryLabel))
        }
        .disabled(!canSubmit)
        .animation(.easeInOut(duration: 0.2), value: canSubmit)
        .padding(.horizontal, LRT.base)
        .padding(.vertical, LRT.md)
        .background(
            LinearGradient(
                colors: [
                    Color(uiColor: .systemGroupedBackground).opacity(0),
                    Color(uiColor: .systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.35)
            )
            .ignoresSafeArea()
        )
    }

    private func staggerAppear() {
        for i in 0..<5 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(i) * 0.08)) {
                appearAnimations[i] = true
            }
        }
    }
}

private struct SectionAppearModifier: ViewModifier {
    let index: Int
    @Binding var animations: [Int: Bool]

    private var isVisible: Bool {
        animations[index] ?? false
    }

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 16)
    }
}

private extension View {
    func sectionAppear(index: Int, animations: Binding<[Int: Bool]>) -> some View {
        modifier(SectionAppearModifier(index: index, animations: animations))
    }
}

enum PatientLabCategory: String, CaseIterable, Identifiable {
    case bloodWork, urine, imaging, cardiac, thyroid, diabetes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bloodWork: return "Blood"
        case .urine: return "Urine"
        case .imaging: return "Imaging"
        case .cardiac: return "Cardiac"
        case .thyroid: return "Thyroid"
        case .diabetes: return "Diabetes"
        }
    }

    var icon: String {
        switch self {
        case .bloodWork: return "drop.fill"
        case .urine: return "flask.fill"
        case .imaging: return "xray"
        case .cardiac: return "heart.fill"
        case .thyroid: return "waveform.path.ecg"
        case .diabetes: return "chart.line.uptrend.xyaxis"
        }
    }

    var availableTests: [String] {
        switch self {
        case .bloodWork: return ["Complete Blood Count (CBC)", "Hemoglobin", "Platelet Count", "ESR", "Blood Grouping", "Liver Function Test (LFT)", "Kidney Function Test (KFT)", "Lipid Profile"]
        case .urine: return ["Routine Urine Analysis", "Urine Culture", "24-Hour Urine Protein", "Urine Microalbumin"]
        case .imaging: return ["X-Ray (Chest)", "X-Ray (Limb)", "Ultrasound (Abdomen)", "CT Scan", "MRI"]
        case .cardiac: return ["ECG", "Echocardiogram", "Troponin Test", "BNP Test", "Stress Test"]
        case .thyroid: return ["TSH", "T3", "T4", "Free T3", "Free T4", "Thyroid Antibodies"]
        case .diabetes: return ["Fasting Blood Sugar", "Post-Prandial Blood Sugar", "HbA1c", "Oral Glucose Tolerance Test"]
        }
    }

    var labTestCategory: LabTestCategory {
        switch self {
        case .bloodWork: return .bloodWork
        case .urine: return .urinalysis
        case .imaging: return .imaging
        case .cardiac: return .cardiology
        case .thyroid: return .hormonal
        case .diabetes: return .bloodWork
        }
    }
}
