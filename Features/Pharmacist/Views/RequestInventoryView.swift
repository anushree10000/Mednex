import SwiftUI

struct RequestInventoryView: View {

    @Environment(DataStore.self) private var dataStore
    @State private var showAddItem = false

    private var requests: [InventoryRequest] {
        dataStore.inventoryRequests
    }

    var body: some View {

        ZStack(alignment: .bottomTrailing) {

            ScrollView {

                VStack(spacing: MedNexTheme.Spacing.md) {

                    if requests.isEmpty {

                        VStack(spacing: 12) {

                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)

                            Text("No Requests Yet")
                                .font(MedNexTheme.Typography.headline)

                            Text("Tap + to request inventory from admin")
                                .font(MedNexTheme.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 140)

                    } else {

                        ForEach(requests) { req in
                            RequestCard(request: req)
                        }

                        Button {
                            sendRequest()
                        } label: {

                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Send to Admin")
                            }
                            .font(MedNexTheme.Typography.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .padding(.top)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, MedNexTheme.Spacing.md)
                .padding(.bottom, 120)
            }

            // Floating Button
            Button {
                showAddItem = true
            } label: {

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(MedNexTheme.Colors.primary)
                    .clipShape(Circle())
                    .shadow(radius: 6)
            }
            .padding(24)

        }
        .navigationTitle("Inventory Requests")

        // identical behavior as InventoryView
        .scrollContentBackground(.hidden)
        .background(
            MedNexTheme.Colors.healthGradient
                .ignoresSafeArea()
        )

        .sheet(isPresented: $showAddItem) {

            AddRequestItemView { item in
                dataStore.addInventoryRequest(item)
            }
        }
    }

    func sendRequest() {
        HapticManager.success()
        // Submit all pending requests to Supabase
        dataStore.submitInventoryRequests(pharmacistId: dataStore.patient.userId)
    }
}
