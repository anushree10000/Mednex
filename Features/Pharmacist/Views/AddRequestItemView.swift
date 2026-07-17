import SwiftUI

struct AddRequestItemView: View {

    @Environment(\.dismiss) var dismiss
    var onAdd: (InventoryRequest) -> Void

    @State private var itemName = ""
    @State private var quantity = ""
    @State private var selectedUnit: RequestUnit = .packs
    @State private var priority: RequestPriority = .normal
    @State private var notes = ""

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 24) {

                    // MARK: Item Name
                    VStack(alignment: .leading, spacing: 8) {

                        Text("Item Name")
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(.secondary)

                        TextField("", text: $itemName)
                            .placeholder(when: itemName.isEmpty) {
                                Text("Search or enter item...")
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // MARK: Quantity + Unit
                    HStack(spacing: 16) {

                        VStack(alignment: .leading, spacing: 8) {

                            Text("Quantity")
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(.secondary)

                            TextField("", text: $quantity)
                                .keyboardType(.numberPad)
                                .placeholder(when: quantity.isEmpty) {
                                    Text("50")
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: 8) {

                            Text("Unit")
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(.secondary)

                            Picker("", selection: $selectedUnit) {
                                ForEach(RequestUnit.allCases, id: \.self) {
                                    Text($0.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // MARK: Priority
                    VStack(alignment: .leading, spacing: 10) {

                        Text("Priority")
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {

                            priorityButton(.normal)
                            priorityButton(.urgent)
                        }
                    }

                    // MARK: Notes
                    VStack(alignment: .leading, spacing: 8) {

                        Text("Additional Notes")
                            .font(MedNexTheme.Typography.caption)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $notes)
                            .frame(height: 120)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // MARK: Add Button
                    Button {

                        let newItem = InventoryRequest(
                            itemName: itemName,
                            quantity: Int(quantity) ?? 0,
                            unit: selectedUnit,
                            priority: priority,
                            notes: notes
                        )

                        onAdd(newItem)
                        dismiss()

                    } label: {

                        HStack(spacing: 8) {

                            Image(systemName: "plus")

                            Text("Add to Request List")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    .padding(.top, 10)

                }
                .padding(20)
            }

            .navigationTitle("Add New Item")

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }

            // 🔥 Gradient like rest of app
            .scrollContentBackground(.hidden)
            .background(
                MedNexTheme.Colors.healthGradient
                    .ignoresSafeArea()
            )
        }
    }

    // MARK: Priority Button

    func priorityButton(_ type: RequestPriority) -> some View {

        Button {

            withAnimation(.easeInOut(duration: 0.2)) {
                priority = type
            }

        } label: {

            Text(type.rawValue)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Group {
                        if priority == type {
                            MedNexTheme.Colors.primary.opacity(0.25)
                        } else {
                            Color(.systemGray6)
                        }
                    }
                )
                .foregroundStyle(
                    priority == type
                    ? MedNexTheme.Colors.primary
                    : .primary
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

extension View {

    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {

        ZStack(alignment: alignment) {

            placeholder().opacity(shouldShow ? 1 : 0)

            self
        }
    }
}
