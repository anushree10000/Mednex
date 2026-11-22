//
//  AdminInventoryView.swift
//  MedNex
//
//  Admin-facing inventory management view with stock tracking.

import SwiftUI

struct AdminInventoryView: View {
    @State private var searchText = ""
    @State private var selectedCategory: InventoryCategory?
    @State private var showAddItem = false
    @State private var animateCards = false
    @Environment(DataStore.self) private var dataStore
    
    private var filteredInventory: [InventoryItem] {
        var items = dataStore.inventory
        if let cat = selectedCategory {
            items = items.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.supplier.localizedCaseInsensitiveContains(searchText) }
        }
        return items
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MedNexTheme.Spacing.lg) {
                // Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MedNexTheme.Spacing.sm) {
                    StatCard(title: "Total Items", value: "\(dataStore.inventory.count)", icon: "shippingbox.fill", tintColor: MedNexTheme.Colors.info)
                    StatCard(title: "Low Stock", value: "\(dataStore.lowStockItems.count)", icon: "exclamationmark.triangle.fill", tintColor: MedNexTheme.Colors.error)
                    StatCard(title: "Total Value", value: "₹\(Int(dataStore.inventory.reduce(0) { $0 + Double($1.stock) * $1.unitPrice }))", icon: "indianrupeesign.circle.fill", tintColor: MedNexTheme.Colors.success)
                    StatCard(title: "Suppliers", value: "\(Set(dataStore.inventory.map { $0.supplier }).count)", icon: "building.2.fill", tintColor: MedNexTheme.Colors.primary)
                }
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 15)
                
                // Low Stock Alert
                let lowStock = dataStore.lowStockItems
                if !lowStock.isEmpty {
                    GlassCard(padding: MedNexTheme.Spacing.sm) {
                        HStack(spacing: MedNexTheme.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundStyle(MedNexTheme.Colors.warning)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(lowStock.count) items need restocking")
                                    .font(MedNexTheme.Typography.subheadline.weight(.medium))
                                    .foregroundStyle(MedNexTheme.Colors.warning)
                                Text(lowStock.map { $0.name }.joined(separator: ", "))
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                        }
                    }
                    .opacity(animateCards ? 1 : 0)
                }
                
                // Search + Filter
                MedNexSearchBar(text: $searchText, placeholder: "Search inventory...")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MedNexTheme.Spacing.xs) {
                        categoryChip(nil, label: "All")
                        ForEach(InventoryCategory.allCases, id: \.self) { cat in
                            categoryChip(cat, label: cat.rawValue)
                        }
                    }
                }
                
                // Inventory List
                if filteredInventory.isEmpty {
                    EmptyStateView(icon: "shippingbox", title: "No Items", message: "No inventory items match your search.")
                        .padding(.top, MedNexTheme.Spacing.xxl)
                } else {
                    ForEach(filteredInventory) { item in
                        GlassCard(padding: MedNexTheme.Spacing.sm) {
                            HStack(spacing: MedNexTheme.Spacing.md) {
                                Image(systemName: categoryIcon(item.category))
                                    .foregroundStyle(MedNexTheme.Colors.primary)
                                    .frame(width: 40, height: 40)
                                    .background(MedNexTheme.Colors.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(MedNexTheme.Typography.subheadline.weight(.medium))
                                    HStack(spacing: MedNexTheme.Spacing.sm) {
                                        Text(item.category.rawValue)
                                        Text("•")
                                        Text(item.supplier)
                                    }
                                    .font(MedNexTheme.Typography.caption)
                                    .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    
                                    Text("₹\(String(format: "%.1f", item.unitPrice))/unit")
                                        .font(MedNexTheme.Typography.caption2)
                                        .foregroundStyle(MedNexTheme.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(item.stock)")
                                        .font(MedNexTheme.Typography.headline)
                                        .foregroundStyle(item.isLowStock ? MedNexTheme.Colors.error : MedNexTheme.Colors.success)
                                    Text("in stock")
                                        .font(MedNexTheme.Typography.caption2)
                                        .foregroundStyle(MedNexTheme.Colors.textTertiary)
                                    
                                    if item.isLowStock {
                                        StatusBadge(text: "Low", color: MedNexTheme.Colors.error, icon: "exclamationmark.triangle.fill")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MedNexTheme.Spacing.md)
            .padding(.bottom, MedNexTheme.Spacing.xxl)
        }
        .navigationTitle("Inventory")
        .scrollContentBackground(.hidden)
        .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddItem = true
                    HapticManager.light()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(MedNexTheme.Colors.primary)
                }
            }
        }
        .onAppear {
            withAnimation(MedNexTheme.Animation.smooth.delay(0.2)) { animateCards = true }
        }
        .sheet(isPresented: $showAddItem) {
            AddInventoryItemSheet()
                .environment(dataStore)
        }
    }
    
    // MARK: - Category Chip
    private func categoryChip(_ category: InventoryCategory?, label: String) -> some View {
        Button {
            selectedCategory = category
            HapticManager.selection()
        } label: {
            Text(label)
                .font(MedNexTheme.Typography.caption.weight(.medium))
                .foregroundStyle(selectedCategory == category ? .black : MedNexTheme.Colors.textSecondary)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.vertical, MedNexTheme.Spacing.xs)
                .background(
                    selectedCategory == category ? Color.white : MedNexTheme.Colors.cardBackground,
                    in: Capsule()
                )
        }
    }
    
    private func categoryIcon(_ cat: InventoryCategory) -> String {
        switch cat {
        case .medication: return "pills.fill"
        case .equipment: return "wrench.and.screwdriver.fill"
        case .consumables: return "bandage.fill"
        case .labSupplies: return "flask.fill"
        case .surgical: return "scissors"
        case .other: return "shippingbox.fill"
        }
    }
}

// MARK: - Add Inventory Item Sheet
struct AddInventoryItemSheet: View {
    @State private var name = ""
    @State private var category: InventoryCategory = .medication
    @State private var stock = ""
    @State private var unitPrice = ""
    @State private var supplier = ""
    @State private var reorderLevel = ""
    @Environment(DataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MedNexTheme.Spacing.lg) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: MedNexTheme.Spacing.md) {
                            Label("Item Details", systemImage: "shippingbox.fill")
                                .font(MedNexTheme.Typography.headline)
                                .foregroundStyle(MedNexTheme.Colors.primary)
                            
                            TextField("Item Name", text: $name)
                                .padding(MedNexTheme.Spacing.sm)
                                .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Category").font(MedNexTheme.Typography.caption).foregroundStyle(MedNexTheme.Colors.textSecondary)
                                Picker("Category", selection: $category) {
                                    ForEach(InventoryCategory.allCases, id: \.self) { cat in
                                        Text(cat.rawValue).tag(cat)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            HStack(spacing: MedNexTheme.Spacing.sm) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Stock").font(MedNexTheme.Typography.caption).foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    TextField("0", text: $stock)
                                        .keyboardType(.numberPad)
                                        .padding(MedNexTheme.Spacing.sm)
                                        .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Unit Price (₹)").font(MedNexTheme.Typography.caption).foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    TextField("0.00", text: $unitPrice)
                                        .keyboardType(.decimalPad)
                                        .padding(MedNexTheme.Spacing.sm)
                                        .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                }
                            }
                            
                            HStack(spacing: MedNexTheme.Spacing.sm) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Reorder Level").font(MedNexTheme.Typography.caption).foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    TextField("10", text: $reorderLevel)
                                        .keyboardType(.numberPad)
                                        .padding(MedNexTheme.Spacing.sm)
                                        .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Supplier").font(MedNexTheme.Typography.caption).foregroundStyle(MedNexTheme.Colors.textSecondary)
                                    TextField("Supplier name", text: $supplier)
                                        .padding(MedNexTheme.Spacing.sm)
                                        .background(MedNexTheme.Colors.elevatedBackground, in: RoundedRectangle(cornerRadius: MedNexTheme.CornerRadius.sm))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                    
                    Button {
                        let item = InventoryItem(
                            name: name,
                            category: category,
                            stock: Int(stock) ?? 0,
                            reorderLevel: Int(reorderLevel) ?? 10,
                            unitPrice: Double(unitPrice) ?? 0,
                            supplier: supplier
                        )
                        dataStore.addInventoryItem(item)
                        HapticManager.success()
                        dismiss()
                    } label: {
                        Text("Add Item")
                    }
                    .buttonStyle(.medNexPrimary)
                    .padding(.horizontal, MedNexTheme.Spacing.md)
                    .disabled(name.isEmpty)
                    .opacity(name.isEmpty ? 0.5 : 1)
                }
                .padding(.bottom, MedNexTheme.Spacing.xxl)
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(MedNexTheme.Colors.healthGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
