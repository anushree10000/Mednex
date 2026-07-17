//
//  RequestCard.swift
//  MedNex
//
//  Created by Abhishek on 13/03/26.
//

import SwiftUI

struct RequestCard: View {

    let request: InventoryRequest

    var body: some View {

        GlassCard {

            HStack {

                VStack(alignment: .leading, spacing: 6) {

                    Text(request.itemName)
                        .font(MedNexTheme.Typography.subheadline.weight(.semibold))

                    Text("\(request.quantity) \(request.unit.rawValue)")
                        .font(MedNexTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusBadge(
                    text: request.priority.rawValue,
                    color: request.priority == .urgent
                    ? MedNexTheme.Colors.error
                    : MedNexTheme.Colors.textSecondary
                )
            }
        }
    }
}
