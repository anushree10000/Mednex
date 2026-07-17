//
//  BillingView.swift
//  MedNex
//
//  Patient-facing billing & insurance claim viewing.

import SwiftUI

struct BillingView: View {
    @State private var selectedSegment = 0
    @State private var animateCards = false
    @State private var billToPay: Bill? = nil
    @Environment(DataStore.self) private var dataStore
    
    private var filteredBills: [Bill] {
        switch selectedSegment {
        case 1: return dataStore.bills.filter { $0.status == .paid }
        case 2: return dataStore.bills.filter { $0.status != .paid }
        default: return dataStore.bills
        }
    }
    
    var body: some View {
        NavigationStack {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Summary Cards
                HStack(spacing: 10) {
                    billingSummaryCard(
                        label: "Total Bills",
                        value: "\(dataStore.bills.count)"
                    )
                    billingSummaryCard(
                        label: "Paid",
                        value: "₹\(Int(dataStore.bills.reduce(0) { $0 + $1.paidAmount }).formatted())"
                    )
                    billingSummaryCard(
                        label: "Pending",
                        value: "₹\(Int(dataStore.bills.reduce(0) { $0 + ($1.totalAmount - $1.paidAmount) }).formatted())"
                    )
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
                        NavigationLink(destination: BillDetailView(bill: bill)) {
                            billCard(bill)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Billing")
        .scrollContentBackground(.hidden)
        .refreshable { await dataStore.refreshFromBackend() }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
        .sheet(item: $billToPay) { bill in
            MedNexPaymentSheet(bill: bill)
        }
        } // NavigationStack
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
                    } label: {
                        Text("Pay Now")
                    }
                    .buttonStyle(.medNexPrimary)
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
    }
    
    // MARK: - Billing Summary Card (compact stat)
    private func billingSummaryCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(.subheadline, design: .default))
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
            Text(value)
                .font(.system(.title2, design: .default, weight: .bold))
                .foregroundStyle(MedNexTheme.Colors.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Payment Sheet
struct MedNexPaymentSheet: View {
    let bill: Bill
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @State private var showConfirm = false
    @State private var isProcessing = false
    @State private var paymentError: String?
    @State private var showPaymentError = false
    @State private var successPaymentId: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MedNexTheme.Spacing.lg) {
                    // Bill Summary
                    GlassCard {
                        VStack(spacing: MedNexTheme.Spacing.sm) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .font(.title2)
                                    .foregroundStyle(MedNexTheme.Colors.primary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Amount Due")
                                        .font(MedNexTheme.Typography.headline)
                                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                    Text("Invoice #\(bill.id.suffix(4).uppercased())")
                                        .font(MedNexTheme.Typography.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                }
                                Spacer()
                            }
                            Divider().overlay(MedNexTheme.Colors.separator)
                            HStack {
                                Text("Total")
                                    .font(MedNexTheme.Typography.subheadline)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                Spacer()
                                Text("₹\(Int(bill.balanceDue))")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(MedNexTheme.Colors.primary)
                            }
                        }
                    }
                    
                    // Pay Online
                    Button { processOnlinePayment() } label: {
                        GlassCard {
                            VStack(spacing: MedNexTheme.Spacing.md) {
                                HStack(spacing: MedNexTheme.Spacing.md) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(
                                                colors: [Color(hex: "2E86DE"), Color(hex: "0652DD")],
                                                startPoint: .topLeading, endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 48, height: 48)
                                        if isProcessing {
                                            ProgressView().tint(.white)
                                        } else {
                                            Image(systemName: "creditcard.fill")
                                                .font(.title3).foregroundStyle(.white)
                                        }
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Pay Online")
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                        Text("UPI • Cards • Net Banking • Wallets")
                                            .font(.system(size: 13))
                                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    }
                                    Spacer()
                                    VStack(spacing: 2) {
                                        Text("₹\(Int(bill.balanceDue))")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundStyle(MedNexTheme.Colors.primary)
                                        Text("Razorpay")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Color(hex: "2E86DE"), in: Capsule())
                                    }
                                }
                                HStack(spacing: 4) {
                                    Image(systemName: "lock.fill").font(.system(size: 10))
                                    Text("PCI DSS Level 1 compliant • 256-bit encryption")
                                        .font(.system(size: 11))
                                }
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .disabled(isProcessing)
                    
                    // Or divider
                    HStack {
                        Rectangle().fill(MedNexTheme.Colors.separator).frame(height: 1)
                        Text("or").font(.system(size: 13, weight: .medium))
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        Rectangle().fill(MedNexTheme.Colors.separator).frame(height: 1)
                    }
                    
                    // Pay at Reception
                    Button {
                        HapticManager.success()
                        dataStore.markBillPaid(bill.id, mode: .cash)
                        showConfirm = true
                    } label: {
                        GlassCard {
                            HStack(spacing: MedNexTheme.Spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(Color(uiColor: .secondarySystemFill))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "banknote.fill")
                                        .font(.title3).foregroundStyle(MedNexTheme.Colors.textSecondary)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pay at Reception")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                    Text("Cash or card at the hospital desk")
                                        .font(.system(size: 13))
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                            }
                        }
                    }
                    .disabled(isProcessing)
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Payment Successful ✅", isPresented: $showConfirm) {
                Button("Done") { dismiss() }
            } message: {
                if let pid = successPaymentId {
                    Text("Payment of ₹\(Int(bill.balanceDue)) received.\nID: \(pid)")
                } else {
                    Text("Payment of ₹\(Int(bill.balanceDue)) has been recorded.")
                }
            }
            .alert("Payment Error", isPresented: $showPaymentError) {
                Button("OK") { }
            } message: {
                Text(paymentError ?? "An error occurred during payment processing.")
            }
            .interactiveDismissDisabled(isProcessing)
        }
    }
    
    private func processOnlinePayment() {
        Task { @MainActor in
            isProcessing = true
            do {
                let service = RazorpayPaymentService.shared
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else {
                    isProcessing = false; return
                }
                var topVC = rootVC
                while let presented = topVC.presentedViewController { topVC = presented }
                
                try await service.startPayment(
                    amount: Int(bill.balanceDue),
                    email: "\(bill.patientId)@mednex.hospital",
                    description: "Bill #\(bill.id.suffix(4).uppercased())",
                    referenceId: bill.id,
                    from: topVC
                ) { result in
                    isProcessing = false
                    switch result {
                    case .success(let pid):
                        successPaymentId = pid
                        dataStore.markBillPaid(bill.id, mode: .upi)
                        showConfirm = true
                    case .cancelled:
                        break
                    case .failed(let error):
                        paymentError = error.localizedDescription
                        showPaymentError = true
                    }
                }
            } catch {
                isProcessing = false
                paymentError = error.localizedDescription
                showPaymentError = true
            }
        }
    }
}



   