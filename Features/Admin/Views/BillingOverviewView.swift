//
//  BillingOverviewView.swift
//  MedNex
//
//  Billing — the list IS the product. Dense but scannable.
//  Revenue summary is a quiet inline bar, not stat cards.

import SwiftUI

struct BillingOverviewView: View {
    @State private var selectedFilter: BillStatusFilter = .all
    @State private var showCreateBill = false
    @Environment(DataStore.self) private var dataStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var bills: [Bill] { dataStore.bills }
    
    var filteredBills: [Bill] {
        switch selectedFilter {
        case .all: return bills
        case .paid: return bills.filter { $0.status == .paid }
        case .unpaid: return bills.filter { $0.status == .unpaid }
        }
    }
    
    private var totalRevenue: Double { bills.reduce(0) { $0 + $1.totalAmount } }
    private var collected: Double { bills.reduce(0) { $0 + $1.paidAmount } }
    private var outstanding: Double { totalRevenue - collected }
    private var collectionRate: Double { totalRevenue > 0 ? min(collected / totalRevenue, 1.0) : 0 }
    private var maxListWidth: CGFloat { horizontalSizeClass == .regular ? 980 : .infinity }
    
    var body: some View {
        List {
            // MARK: - Revenue Bar (inline, not cards)
            Section {
                VStack(spacing: MedNexTheme.Spacing.xs) {
                    HStack {
                        Text("₹\(Int(totalRevenue))")
                            .font(.title.weight(.bold).monospacedDigit())
                            .foregroundStyle(MedNexTheme.Colors.textPrimary)
                        Spacer()
                        Text(bills.count == 1 ? "1 bill" : "\(bills.count) bills")
                            .font(.subheadline)
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                    }
                    HStack {
                        Text("Collection Rate")
                            .font(.caption)
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        Spacer()
                        Text("\(Int(collectionRate * 100))%")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(MedNexTheme.Colors.success)
                    }
                    
                    // Collection progress bar
                    if totalRevenue > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(MedNexTheme.Colors.separator)
                                    .frame(height: 6)
                                Capsule()
                                    .fill(MedNexTheme.Colors.success)
                                    .frame(width: geo.size.width * min(collected / totalRevenue, 1.0), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    
                    HStack {
                        Text("Collected ₹\(Int(collected))")
                            .foregroundStyle(MedNexTheme.Colors.success)
                        Spacer()
                        Text("Outstanding ₹\(Int(outstanding))")
                            .foregroundStyle(outstanding > 0 ? MedNexTheme.Colors.warning : MedNexTheme.Colors.textTertiary)
                    }
                    .font(.caption)
                }
                .listRowBackground(Color.clear)
            }
            
            // MARK: - Filter
            Section {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(BillStatusFilter.allCases, id: \.self) { f in
                        Text(f.rawValue.capitalized).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 1)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
            }
            
            // MARK: - Bills
            if filteredBills.isEmpty {
                ContentUnavailableView(
                    "No \(selectedFilter == .all ? "" : selectedFilter.rawValue + " ")bills",
                    systemImage: "doc.text",
                    description: Text("Bills you create will appear here.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredBills) { bill in
                    NavigationLink(value: bill) {
                        billRow(bill)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .frame(maxWidth: maxListWidth)
        .frame(maxWidth: .infinity, alignment: .center)
        .navigationTitle("Billing")
        .navigationDestination(for: Bill.self) { bill in
            BillDetailView(bill: bill)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCreateBill = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.large)
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Create bill")
                .accessibilityHint("Opens a form to create a new bill")
            }
        }
        .sheet(isPresented: $showCreateBill) {
            CreateBillSheet()
        }
        .refreshable {
            await dataStore.refreshFromBackend()
        }
    }
    
    // MARK: - Bill Row
    // Lightweight — no icon boxes. Patient name is dominant.
    
    private func billRow(_ bill: Bill) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(bill.patientName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                
                Text(bill.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text("₹\(Int(bill.totalAmount))")
                    .font(.body.weight(.semibold).monospacedDigit())
                    .foregroundStyle(MedNexTheme.Colors.textPrimary)
                
                Text(bill.status.displayName)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(bill.status == .paid ? MedNexTheme.Colors.success : MedNexTheme.Colors.warning)
            }
        }
        .padding(.vertical, 2)
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
    @State private var patientSearchText = ""
    @State private var showPatientPicker = false
    @State private var lineItems: [(title: String, qty: String, unitPrice: String, category: BillItemCategory)] = [("", "1", "", .consultation)]
    @State private var taxPercentStr = ""
    @State private var discountPercentStr = ""
    @State private var showSaved = false
    
    private var patients: [(id: String, name: String, appointmentId: String)] {
        return dataStore.allPatients.map { patient in
            let latestAppointment = dataStore.appointments
                .filter { $0.patientId == patient.id }
                .sorted { $0.dateTime > $1.dateTime }
                .first
            return (
                id: patient.id,
                name: patient.personalInfo.fullName.isEmpty ? "Patient \(patient.id.prefix(6))" : patient.personalInfo.fullName,
                appointmentId: latestAppointment?.id ?? ""
            )
        }.sorted { $0.name < $1.name }
    }

    private var filteredPatients: [(id: String, name: String, appointmentId: String)] {
        let trimmed = patientSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return patients }
        return patients.filter { patient in
            patient.name.localizedCaseInsensitiveContains(trimmed)
            || patient.id.localizedCaseInsensitiveContains(trimmed)
        }
    }
    
    private var selectedPatientName: String { patients.first(where: { $0.id == selectedPatientId })?.name ?? "" }
    private var selectedAppointmentId: String { patients.first(where: { $0.id == selectedPatientId })?.appointmentId ?? "" }
    
    private var subtotal: Double {
        lineItems.reduce(0) { total, item in
            let qty = Double(item.qty) ?? 0
            let price = Double(item.unitPrice) ?? 0
            return total + qty * price
        }
    }
    
    private var taxPercent: Double { min(max(Double(taxPercentStr) ?? 0, 0), 100) }
    private var discountPercent: Double { min(max(Double(discountPercentStr) ?? 0, 0), 100) }
    private var taxAmount: Double { subtotal * taxPercent / 100 }
    private var discountAmount: Double { subtotal * discountPercent / 100 }
    private var grandTotal: Double { max(0, subtotal + taxAmount - discountAmount) }
    
    private var isValid: Bool {
        !selectedPatientId.isEmpty &&
        lineItems.contains(where: { !$0.title.isEmpty && (Double($0.unitPrice) ?? 0) > 0 })
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Patient
                Section("Patient") {
                    Button {
                        showPatientPicker = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedPatientName.isEmpty ? "Select Patient" : selectedPatientName)
                                    .foregroundStyle(selectedPatientName.isEmpty ? MedNexTheme.Colors.textTertiary : MedNexTheme.Colors.textPrimary)
                                if let selected = patients.first(where: { $0.id == selectedPatientId }) {
                                    Text("ID \(selected.id.prefix(8))")
                                        .font(.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        }
                    }
                    .accessibilityLabel(selectedPatientName.isEmpty ? "Select patient" : "Selected patient \(selectedPatientName)")
                }
                
                // Billable services / charges
                Section("Billable Charges") {
                    ForEach(lineItems.indices, id: \.self) { i in
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.sm) {
                            Text("Charge \(i + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)

                            TextField("Service or charge name", text: Binding(
                                get: { lineItems[i].title },
                                set: { lineItems[i].title = $0 }
                            ))
                            .textInputAutocapitalization(.words)
                            
                            HStack(spacing: MedNexTheme.Spacing.md) {
                                Picker("Category", selection: Binding(
                                    get: { lineItems[i].category },
                                    set: { lineItems[i].category = $0 }
                                )) {
                                    ForEach(BillItemCategory.allCases, id: \.self) { cat in
                                        Text(cat.displayName).tag(cat)
                                    }
                                }
                                .pickerStyle(.menu)
                                .font(.subheadline)
                                
                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Quantity")
                                        .font(.caption2)
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    TextField("1", text: Binding(
                                        get: { lineItems[i].qty },
                                        set: { lineItems[i].qty = $0 }
                                    ))
                                    .keyboardType(.numberPad)
                                    .frame(width: 52)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 6)
                                    .background(MedNexTheme.Colors.secondaryBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Unit Price")
                                        .font(.caption2)
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    HStack(spacing: 4) {
                                        Text("₹")
                                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    TextField("0", text: Binding(
                                        get: { lineItems[i].unitPrice },
                                        set: { lineItems[i].unitPrice = $0 }
                                    ))
                                    .keyboardType(.decimalPad)
                                    .frame(width: 76)
                                    .multilineTextAlignment(.trailing)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(MedNexTheme.Colors.secondaryBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }
                            .font(.subheadline)
                            .accessibilityElement(children: .contain)

                            HStack {
                                Text("Line total")
                                    .font(.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                Spacer()
                                let qty = Double(lineItems[i].qty) ?? 0
                                let unitPrice = Double(lineItems[i].unitPrice) ?? 0
                                Text("₹\(Int(qty * unitPrice))")
                                    .font(.subheadline.weight(.semibold).monospacedDigit())
                            }
                            
                            if lineItems.count > 1 {
                                Button(role: .destructive) {
                                    lineItems.remove(at: i)
                                } label: {
                                    Label("Remove Charge", systemImage: "trash")
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.vertical, MedNexTheme.Spacing.xs)
                    }
                    
                    Button { lineItems.append(("", "1", "", .consultation)) } label: {
                        Label("Add Charge", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                
                // Adjustments — plain, calm
                Section("Adjustments") {
                    HStack {
                        Text("Tax (%)")
                        Spacer()
                        TextField("0", text: $taxPercentStr)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Discount (%)")
                        Spacer()
                        TextField("0", text: $discountPercentStr)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Tax amount")
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        Spacer()
                        Text("₹\(Int(taxAmount))")
                            .monospacedDigit()
                    }
                    HStack {
                        Text("Discount amount")
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        Spacer()
                        Text("₹\(Int(discountAmount))")
                            .monospacedDigit()
                    }
                }
                
                // Total
                Section {
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text("₹\(Int(grandTotal))")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(MedNexTheme.Colors.primary)
                    }
                }
                
                // Submit
                Section {
                    Button { createBill() } label: {
                        Text("Create Bill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("New Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Bill Created", isPresented: $showSaved) {
                Button("Done") { dismiss() }
            } message: {
                Text("₹\(Int(grandTotal)) bill created for \(selectedPatientName).")
            }
            .sheet(isPresented: $showPatientPicker) {
                PatientPickerSheet(
                    patients: filteredPatients,
                    searchText: $patientSearchText,
                    selectedPatientId: $selectedPatientId
                )
            }
        }
    }
    
    private func createBill() {
        let items = lineItems.compactMap { item -> BillItem? in
            let qty = Int(item.qty) ?? 0
            let price = Double(item.unitPrice) ?? 0
            guard !item.title.isEmpty, price > 0 else { return nil }
            return BillItem(description: item.title, quantity: qty, unitPrice: price, total: Double(qty) * price, category: item.category)
        }
        
        _ = dataStore.createBill(
            appointmentId: selectedAppointmentId,
            patientId: selectedPatientId,
            patientName: selectedPatientName,
            items: items,
            tax: taxAmount,
            discount: discountAmount
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

private struct PatientPickerSheet: View {
    let patients: [(id: String, name: String, appointmentId: String)]
    @Binding var searchText: String
    @Binding var selectedPatientId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if patients.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(patients, id: \.id) { patient in
                        Button {
                            selectedPatientId = patient.id
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(patient.name)
                                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                                    Text("ID \(patient.id.prefix(8))")
                                        .font(.caption)
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                }
                                Spacer()
                                if selectedPatientId == patient.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(MedNexTheme.Colors.success)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search by name or patient ID")
            .navigationTitle("Select Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
