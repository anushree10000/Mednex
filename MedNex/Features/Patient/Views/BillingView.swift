//
//  BillingView.swift
//  MedNex
//
//  Patient-facing billing & insurance claim viewing.

import SwiftUI
import Combine
#if canImport(StripePaymentSheet)
import StripePaymentSheet
#endif

struct BillingView: View {
    @State private var selectedSegment = 0
    @State private var animateCards = false
    @State private var billToPay: Bill? = nil
    @State private var showPaymentSheet = false
    @Environment(DataStore.self) private var dataStore
    
    private var filteredBills: [Bill] {
        switch selectedSegment {
        case 1: return dataStore.bills.filter { $0.status == .paid }
        case 2: return dataStore.bills.filter { $0.status != .paid }
        default: return dataStore.bills
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Summary Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                    StatCard(title: "Total Bills", value: "\(dataStore.bills.count)", icon: "doc.text.fill", tintColor: MedNexTheme.Colors.info)
                    StatCard(title: "Amount Paid", value: "₹\(Int(dataStore.bills.reduce(0) { $0 + $1.paidAmount }))", icon: "checkmark.circle.fill", tintColor: MedNexTheme.Colors.success)
                    StatCard(title: "Pending", value: "₹\(Int(dataStore.bills.reduce(0) { $0 + ($1.totalAmount - $1.paidAmount) }))", icon: "clock.fill", tintColor: MedNexTheme.Colors.warning)
                    StatCard(title: "Insurance", value: "\(dataStore.bills.filter { $0.paymentMode == .insurance }.count) Claim\(dataStore.bills.filter { $0.paymentMode == .insurance }.count == 1 ? "" : "s")", icon: "shield.checkered", tintColor: MedNexTheme.Colors.primary)
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 15)
                
                // Segment Filter
                Picker("Filter", selection: $selectedSegment) {
                    Text("All").tag(0)
                    Text("Paid").tag(1)
                    Text("Unpaid").tag(2)
                }
                .pickerStyle(.segmented)
                
                // Bill Cards
                if filteredBills.isEmpty {
                    EmptyStateView(icon: "doc.text", title: "No Bills", message: "No bills match the selected filter.")
                        .padding(.top, MedNexTheme.Spacing.xxl)
                } else {
                    ForEach(filteredBills) { bill in
                        billCard(bill)
                    }
                }
                
                // Insurance Claims Section
                insuranceSection
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Billing")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
        .sheet(isPresented: $showPaymentSheet) {
            if let bill = billToPay {
                MedNexPaymentSheet(bill: bill)
            }
        }
    }
    
    // MARK: - Bill Card
    private func billCard(_ bill: Bill) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                        Text("Invoice #\(bill.id.suffix(4).uppercased())")
                            .font(MedNexTheme.Typography.headline)
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        Text(bill.createdAt.medicalFormat)
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                    }
                    Spacer()
                    StatusBadge(text: bill.status.displayName, color: Color(hex: bill.status.color))
                }
                
                Divider().overlay(MedNexTheme.Colors.separator)
                
                ForEach(bill.items) { item in
                    HStack {
                        Text(item.description)
                            .font(MedNexTheme.Typography.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        Spacer()
                        Text("₹\(Int(item.total))")
                            .font(MedNexTheme.Typography.subheadline.weight(.medium))
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    }
                }
                
                Divider().overlay(MedNexTheme.Colors.separator)
                
                HStack {
                    Text("Total")
                        .font(MedNexTheme.Typography.headline)
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    Spacer()
                    Text("₹\(Int(bill.totalAmount))")
                        .font(MedNexTheme.Typography.title3.weight(.bold))
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
                
                if let mode = bill.paymentMode {
                    HStack(spacing: MedNexTheme.Spacing.xs) {
                        Image(systemName: "creditcard.fill")
                            .font(.caption)
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        Text("Paid via \(mode.displayName)")
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                    }
                }
                
                if bill.status != .paid {
                    Button {
                        billToPay = bill
                        showPaymentSheet = true
                    } label: {
                        Text("Pay Now")
                    }
                    .buttonStyle(.medNexPrimary)
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
    }
    
    // MARK: - Insurance Section
    private var insuranceSection: some View {
        let insuranceBills = dataStore.bills.filter { $0.paymentMode == .insurance }
        let totalInsurancePaid = insuranceBills.reduce(0) { $0 + $1.paidAmount }
        
        return VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
            SectionHeader(title: "Insurance Claims")
            
            GlassCard {
                VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "shield.checkered")
                            .font(.title2)
                            .foregroundStyle(MedNexTheme.Colors.primary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Health Shield Plus")
                                .font(MedNexTheme.Typography.headline)
                                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                            Text("Policy #HSP-2024-78345")
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        StatusBadge(text: "Active", color: MedNexTheme.Colors.success)
                    }
                    
                    Divider().overlay(MedNexTheme.Colors.separator)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Coverage")
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            Text("₹5,00,000")
                                .font(MedNexTheme.Typography.headline)
                                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Used")
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            Text("₹\(Int(totalInsurancePaid))")
                                .font(MedNexTheme.Typography.headline)
                                .foregroundStyle(MedNexTheme.Colors.warning)
                        }
                    }
                    
                    ProgressView(value: totalInsurancePaid, total: 500000)
                        .tint(MedNexTheme.Colors.primary)
                    
                    Text("Valid until: Dec 2026")
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
            }
            
            // Recent Claims
            if !insuranceBills.isEmpty {
                ForEach(insuranceBills.prefix(3)) { bill in
                    GlassCard(padding: MedNexTheme.Spacing.sm) {
                        HStack(spacing: MedNexTheme.Spacing.sm) {
                            Image(systemName: "doc.text.below.ecg.fill")
                                .foregroundStyle(MedNexTheme.Colors.info)
                                .frame(width: 36, height: 36)
                                .background(MedNexTheme.Colors.info.opacity(0.12), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Claim #\(bill.id.suffix(6).uppercased())")
                                    .font(MedNexTheme.Typography.subheadline.weight(.medium))
                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                Text("\(bill.items.first?.description ?? "Claim") — ₹\(Int(bill.totalAmount))")
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            StatusBadge(text: bill.status == .paid ? "Approved" : "Pending", color: bill.status == .paid ? MedNexTheme.Colors.success : MedNexTheme.Colors.warning)
                        }
                    }
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }
}

// MARK: - Payment Sheet
struct MedNexPaymentSheet: View {
    let bill: Bill
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @State private var selectedMode: PaymentMode? = nil
    @State private var showConfirm = false
    @State private var isProcessing = false
    @State private var stripeError: String?
    @State private var showStripeError = false
    
    #if canImport(StripePaymentSheet)
    @StateObject private var stripeService = StripePaymentService.shared
    #endif
    
    /// Modes that route through Stripe
    private var isStripeMode: Bool {
        guard let mode = selectedMode else { return false }
        return [.upi, .card, .bankTransfer].contains(mode)
    }
    
    private let paymentOptions: [(mode: PaymentMode, icon: String, description: String)] = [
        (.upi, "indianrupeesign.circle.fill", "Pay instantly via UPI"),
        (.card, "creditcard.fill", "Credit or Debit Card"),
        (.cash, "banknote.fill", "Pay at the reception"),
        (.insurance, "shield.checkered", "Claim from insurance provider"),
        (.bankTransfer, "building.columns.fill", "Direct bank transfer (NEFT/RTGS)")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MedNexTheme.Spacing.lg) {
                    // Bill Summary
                    GlassCard {
                        VStack(spacing: MedNexTheme.Spacing.sm) {
                            HStack {
                                Text("Amount Due")
                                    .font(MedNexTheme.Typography.subheadline)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                Spacer()
                                Text("₹\(Int(bill.balanceDue))")
                                    .font(MedNexTheme.Typography.title2.weight(.bold))
                                    .foregroundStyle(MedNexTheme.Colors.primary)
                            }
                            Text("Invoice #\(bill.id.suffix(4).uppercased())")
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // Payment Methods
                    GlassCard {
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                            Label("Select Payment Method", systemImage: "creditcard")
                                .font(MedNexTheme.Typography.headline)
                                .foregroundStyle(MedNexTheme.Colors.primary)
                            
                            ForEach(paymentOptions, id: \.mode) { option in
                                Button {
                                    withAnimation { selectedMode = option.mode }
                                } label: {
                                    HStack(spacing: MedNexTheme.Spacing.md) {
                                        Image(systemName: option.icon)
                                            .font(.title2)
                                            .foregroundStyle(selectedMode == option.mode ? MedNexTheme.Colors.primary : MedNexTheme.Colors.textSecondary)
                                            .frame(width: 40)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: MedNexTheme.Spacing.xs) {
                                                Text(option.mode.displayName)
                                                    .font(MedNexTheme.Typography.headline)
                                                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                                
                                                // Stripe badge for gateway-backed methods
                                                if [PaymentMode.upi, .card, .bankTransfer].contains(option.mode) {
                                                    Text("Stripe")
                                                        .font(.system(size: 9, weight: .bold))
                                                        .foregroundStyle(.white)
                                                        .padding(.horizontal, 5)
                                                        .padding(.vertical, 2)
                                                        .background(Color(hex: "635BFF"), in: Capsule())
                                                }
                                            }
                                            Text(option.description)
                                                .font(MedNexTheme.Typography.caption)
                                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: selectedMode == option.mode ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedMode == option.mode ? MedNexTheme.Colors.primary : MedNexTheme.Colors.textTertiary)
                                    }
                                    .padding(MedNexTheme.Spacing.sm)
                                    .background(
                                        selectedMode == option.mode ? MedNexTheme.Colors.primary.opacity(0.08) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm)
                                            .stroke(selectedMode == option.mode ? MedNexTheme.Colors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    
                    // Stripe branding note
                    if isStripeMode {
                        HStack(spacing: MedNexTheme.Spacing.xs) {
                            Image(systemName: "lock.shield.fill")
                                .font(.caption)
                            Text("Secured by Stripe — your card details never touch our servers")
                                .font(MedNexTheme.Typography.caption2)
                        }
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // Confirm / Pay
                    Button {
                        processPayment()
                    } label: {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(isStripeMode ? "Pay with Stripe" : "Confirm Payment")
                        }
                    }
                    .buttonStyle(.medNexPrimary)
                    .disabled(selectedMode == nil || isProcessing)
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Payment Successful", isPresented: $showConfirm) {
                Button("Done") { dismiss() }
            } message: {
                Text("Payment of ₹\(Int(bill.balanceDue)) via \(selectedMode?.displayName ?? "") has been recorded.")
            }
            .alert("Payment Error", isPresented: $showStripeError) {
                Button("OK") { }
            } message: {
                Text(stripeError ?? "An error occurred during payment processing.")
            }
        }
    }
    
    // MARK: - Process Payment
    
    private func processPayment() {
        guard let mode = selectedMode else { return }
        
        // Cash & Insurance → record locally, no gateway needed
        if mode == .cash || mode == .insurance {
            HapticManager.success()
            dataStore.markBillPaid(bill.id, mode: mode)
            showConfirm = true
            return
        }
        
        // UPI / Card / Bank Transfer → route through Stripe
        #if canImport(StripePaymentSheet)
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                // Prepare Stripe PaymentSheet
                let amountInPaise = Int(bill.balanceDue * 100) // Stripe expects smallest currency unit
                try await stripeService.preparePaymentSheet(
                    amountInPaise: amountInPaise,
                    currency: "inr",
                    patientEmail: bill.patientId, // We use patientId; backend resolves email
                    billId: bill.id
                )
                
                // Present Stripe's PaymentSheet
                guard let sheet = stripeService.paymentSheet else {
                    stripeError = "Could not initialize payment. Please try again."
                    showStripeError = true
                    return
                }
                
                // PaymentSheet.present() uses a completion handler, bridge to async
                await MainActor.run {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        sheet.present(from: rootVC, completion: { result in
                            stripeService.handlePaymentResult(result)
                            // Retrieve result from state since PaymentSheetResult isn't Equatable without import StripePaymentSheet in this file
                            switch stripeService.lastResult {
                            case .success:
                                dataStore.markBillPaid(bill.id, mode: mode)
                                showConfirm = true
                            case .cancelled:
                                break // User cancelled, do nothing
                            case .failed(let error):
                                stripeError = error.localizedDescription
                                showStripeError = true
                            case .none:
                                break
                            }
                        })
                    }
                }
            } catch {
                stripeError = error.localizedDescription
                showStripeError = true
            }
        }
        #else
        // Stripe SDK not available — fall back to local recording
        HapticManager.success()
        dataStore.markBillPaid(bill.id, mode: mode)
        showConfirm = true
        #endif
    }
}
