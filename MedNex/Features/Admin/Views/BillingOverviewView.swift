//
//  BillingOverviewView.swift
//  MedNex
//

import SwiftUI

struct BillingOverviewView: View {
    @State private var selectedFilter: BillStatusFilter = .all
    @State private var showCreateBill = false
    @Environment(DataStore.self) private var dataStore
    
    private var bills: [Bill] { dataStore.bills }
    
    var filteredBills: [Bill] {
        switch selectedFilter {
        case .all: return bills
        case .paid: return bills.filter { $0.status == .paid }
        case .unpaid: return bills.filter { $0.status == .unpaid }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Summary
            HStack(spacing: MedNexTheme.Spacing.sm) {
                summaryCard(title: "Total Revenue", value: "₹\(Int(bills.reduce(0) { $0 + $1.totalAmount }))", color: MedNexTheme.Colors.success)
                summaryCard(title: "Collected", value: "₹\(Int(bills.reduce(0) { $0 + $1.paidAmount }))", color: MedNexTheme.Colors.primary)
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.vertical, MedNexTheme.Spacing.sm)
            
            Picker("Filter", selection: $selectedFilter) {
                ForEach(BillStatusFilter.allCases, id: \.self) { f in Text(f.rawValue.capitalized).tag(f) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, MedNexTheme.Spacing.md)
            
            ScrollView {
                LazyVStack(spacing: MedNexTheme.Spacing.sm) {
                    ForEach(filteredBills) { bill in
                        GlassCard {
                            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bill.patientName)
                                            .font(MedNexTheme.Typography.headline)
                                        Text(bill.createdAt.shortDate)
                                            .font(MedNexTheme.Typography.caption)
                                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("₹\(Int(bill.totalAmount))")
                                            .font(MedNexTheme.Typography.title3)
                                            .foregroundStyle(MedNexTheme.Colors.primary)
                                        StatusBadge(text: bill.status.displayName, color: bill.status == .paid ? MedNexTheme.Colors.success : MedNexTheme.Colors.warning)
                                    }
                                }
                                
                                Divider()
                                
                                ForEach(bill.items) { item in
                                    HStack {
                                        Text(item.description)
                                            .font(MedNexTheme.Typography.caption)
                                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                        Spacer()
                                        Text("₹\(Int(item.total))")
                                            .font(MedNexTheme.Typography.caption.weight(.medium))
                                    }
                                }
                                
                                if let mode = bill.paymentMode {
                                    HStack {
                                        Text("Payment: \(mode.rawValue)")
                                            .font(MedNexTheme.Typography.caption)
                                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.top, MedNexTheme.Spacing.sm)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
        }
        .navigationTitle("Billing")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateBill = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showCreateBill) {
            CreateBillSheet()
        }
    }
    
    private func summaryCard(title: String, value: String, color: Color) -> some View {
        GlassCard(padding: MedNexTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: MedNexTheme.Spacing.xxs) {
                Text(title)
                    .font(MedNexTheme.Typography.caption)
                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                Text(value)
                    .font(MedNexTheme.Typography.title3)
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

enum BillStatusFilter: String, CaseIterable {
    case all, paid, unpaid
}

// MARK: - Create Bill Sheet
struct CreateBillSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    
    @State private var selectedPatientId = ""
    @State private var lineItems: [(desc: String, qty: String, price: String)] = [("", "1", "")]
    @State private var taxStr = ""
    @State private var discountStr = ""
    @State private var showSaved = false
    
    private var patients: [(id: String, name: String, appointmentId: String)] {
        let grouped = Dictionary(grouping: dataStore.appointments, by: \.patientId)
        return grouped.compactMap { (patientId, appointments) in
            guard let latest = appointments.sorted(by: { $0.dateTime > $1.dateTime }).first else { return nil }
            return (id: patientId, name: latest.patientName, appointmentId: latest.id)
        }
        .sorted { $0.name < $1.name }
    }
    
    private var selectedPatientName: String {
        patients.first(where: { $0.id == selectedPatientId })?.name ?? ""
    }
    
    private var selectedAppointmentId: String {
        patients.first(where: { $0.id == selectedPatientId })?.appointmentId ?? ""
    }
    
    private var subtotal: Double {
        lineItems.reduce(0) { total, item in
            let qty = Double(item.qty) ?? 0
            let price = Double(item.price) ?? 0
            return total + qty * price
        }
    }
    
    private var tax: Double { Double(taxStr) ?? 0 }
    private var discount: Double { Double(discountStr) ?? 0 }
    private var grandTotal: Double { subtotal + tax - discount }
    
    private var isValid: Bool {
        !selectedPatientId.isEmpty &&
        lineItems.contains(where: { !$0.desc.isEmpty && (Double($0.price) ?? 0) > 0 })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MedNexTheme.Spacing.lg) {
                    // Patient Picker
                    GlassCard {
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                            Label("Patient", systemImage: "person.fill")
                                .font(MedNexTheme.Typography.headline)
                                .foregroundStyle(MedNexTheme.Colors.primary)
                            
                            Menu {
                                ForEach(patients, id: \.id) { p in
                                    Button(p.name) { selectedPatientId = p.id }
                                }
                            } label: {
                                HStack {
                                    Text(selectedPatientName.isEmpty ? "Select patient..." : selectedPatientName)
                                        .foregroundStyle(selectedPatientName.isEmpty ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                }
                                .padding(MedNexTheme.Spacing.sm)
                                .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                            }
                        }
                    }
                    
                    // Line Items
                    GlassCard {
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                            Label("Line Items", systemImage: "list.bullet")
                                .font(MedNexTheme.Typography.headline)
                                .foregroundStyle(MedNexTheme.Colors.primary)
                            
                            ForEach(lineItems.indices, id: \.self) { i in
                                HStack(spacing: MedNexTheme.Spacing.xs) {
                                    TextField("Description", text: Binding(
                                        get: { lineItems[i].desc },
                                        set: { lineItems[i].desc = $0 }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity)
                                    
                                    TextField("Qty", text: Binding(
                                        get: { lineItems[i].qty },
                                        set: { lineItems[i].qty = $0 }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                    .frame(width: 50)
                                    
                                    TextField("Price", text: Binding(
                                        get: { lineItems[i].price },
                                        set: { lineItems[i].price = $0 }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 80)
                                    
                                    if lineItems.count > 1 {
                                        Button {
                                            lineItems.remove(at: i)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(MedNexTheme.Colors.error)
                                        }
                                    }
                                }
                            }
                            
                            Button {
                                lineItems.append(("", "1", ""))
                            } label: {
                                Label("Add Item", systemImage: "plus.circle")
                                    .font(MedNexTheme.Typography.subheadline)
                            }
                        }
                    }
                    
                    // Tax / Discount / Total
                    GlassCard {
                        VStack(spacing: MedNexTheme.Spacing.sm) {
                            HStack {
                                Text("Subtotal")
                                    .font(MedNexTheme.Typography.subheadline)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                Spacer()
                                Text("₹\(Int(subtotal))")
                                    .font(MedNexTheme.Typography.subheadline.weight(.medium))
                            }
                            
                            HStack {
                                Text("Tax")
                                    .font(MedNexTheme.Typography.subheadline)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                Spacer()
                                TextField("0", text: $taxStr)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            HStack {
                                Text("Discount")
                                    .font(MedNexTheme.Typography.subheadline)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                Spacer()
                                TextField("0", text: $discountStr)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Grand Total")
                                    .font(MedNexTheme.Typography.headline)
                                Spacer()
                                Text("₹\(Int(grandTotal))")
                                    .font(MedNexTheme.Typography.title3.weight(.bold))
                                    .foregroundStyle(MedNexTheme.Colors.primary)
                            }
                        }
                    }
                    
                    // Submit
                    Button {
                        createBill()
                    } label: {
                        Text("Create Bill")
                    }
                    .buttonStyle(.medNexPrimary)
                    .disabled(!isValid)
                }
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
            .navigationTitle("New Bill")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Bill Created", isPresented: $showSaved) {
                Button("Done") { dismiss() }
            } message: {
                Text("Bill for ₹\(Int(grandTotal)) has been created for \(selectedPatientName).")
            }
        }
    }
    
    private func createBill() {
        let items = lineItems.compactMap { item -> BillItem? in
            let qty = Int(item.qty) ?? 0
            let price = Double(item.price) ?? 0
            guard !item.desc.isEmpty, price > 0 else { return nil }
            return BillItem(
                description: item.desc,
                quantity: qty,
                unitPrice: price,
                total: Double(qty) * price
            )
        }
        
        _ = dataStore.createBill(
            appointmentId: selectedAppointmentId,
            patientId: selectedPatientId,
            patientName: selectedPatientName,
            items: items,
            tax: tax,
            discount: discount
        )
        
        dataStore.addNotification(
            title: "New Bill Created",
            message: "Bill of ₹\(Int(grandTotal)) created for \(selectedPatientName).",
            type: .paymentDue
        )
        
        HapticManager.success()
        showSaved = true
    }
}
