//
//  BillDetailView.swift
//  MedNex
//
//  Bill detail — the amount is everything. Big number at top.
//  Line items are a clean table, no extra boxing.

import SwiftUI

struct BillDetailView: View {
    let bill: Bill
    @Environment(DataStore.self) private var dataStore
    
    private var subtotal: Double { bill.items.reduce(0) { $0 + $1.total } }
    private var taxAmount: Double { bill.totalAmount - subtotal }
    private var balance: Double { bill.totalAmount - bill.paidAmount }
    
    var body: some View {
        List {
            // Amount — the hero. Big, centered.
            Section {
                VStack(spacing: 8) {
                    Text("₹\(Int(bill.totalAmount))")
                        .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(MedNexTheme.Colors.textPrimary)
                    
                    Text(bill.status.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(bill.status == .paid ? MedNexTheme.Colors.success : MedNexTheme.Colors.warning)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MedNexTheme.Spacing.md)
                .listRowBackground(Color.clear)
            }
            
            // Patient & date — plain info, no icons
            Section {
                HStack {
                    Text(bill.patientName)
                        .font(.body.weight(.medium))
                    Spacer()
                    Text(bill.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                }
                
                if let paidAt = bill.paidAt {
                    HStack {
                        Text("Paid")
                            .foregroundStyle(MedNexTheme.Colors.success)
                        Spacer()
                        Text(paidAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(MedNexTheme.Colors.textTertiary)
                    }
                    .font(.subheadline)
                }
                
                if let mode = bill.paymentMode {
                    HStack {
                        Text("Payment method")
                            .foregroundStyle(MedNexTheme.Colors.textSecondary)
                        Spacer()
                        Text(mode.displayName)
                    }
                    .font(.subheadline)
                }
            }
            
            // Line items — clean table layout
            Section("Items") {
                ForEach(bill.items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.description)
                                .font(.subheadline.weight(.medium))
                            Text("\(item.quantity) × ₹\(Int(item.unitPrice))")
                                .font(.caption)
                                .foregroundStyle(MedNexTheme.Colors.textTertiary)
                        }
                        Spacer()
                        Text("₹\(Int(item.total))")
                            .font(.subheadline.monospacedDigit())
                    }
                    .padding(.vertical, 1)
                }
            }
            
            // Totals — aligned right, no icons
            Section {
                totalRow("Subtotal", "₹\(Int(subtotal))")
                
                if taxAmount > 0 {
                    totalRow("Tax", "₹\(Int(taxAmount))")
                }
                
                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text("₹\(Int(bill.totalAmount))")
                        .font(.headline.monospacedDigit())
                }
                
                if bill.paidAmount > 0 {
                    totalRow("Paid", "₹\(Int(bill.paidAmount))", color: MedNexTheme.Colors.success)
                }
                
                if balance > 0 {
                    totalRow("Balance due", "₹\(Int(balance))", color: MedNexTheme.Colors.error)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Bill")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func totalRow(_ label: String, _ value: String, color: Color = MedNexTheme.Colors.textSecondary) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .font(.subheadline)
    }
}
