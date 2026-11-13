//
//  MDQuantityUnitRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 19.10.23.
//

import SwiftUI

struct MDQuantityUnitRowView: View {
    var quantityUnit: MDQuantityUnit

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text(quantityUnit.name)
                    .font(.headline)
                if !quantityUnit.namePlural.isEmpty {
                    Text("(\(quantityUnit.namePlural))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(quantityUnit.active ? .primary : .secondary)
            // Disabled is spelled out, not only shown by the dimmed color ("Disabled" matches the Grocy web app).
            if !quantityUnit.active {
                Text("Disabled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !quantityUnit.mdQuantityUnitDescription.isEmpty {
                Text(quantityUnit.mdQuantityUnitDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        MDQuantityUnitRowView(quantityUnit: MDQuantityUnit(id: 1, name: "Quantity unit", namePlural: "Quantity units", mdQuantityUnitDescription: "Description"))
    }
}
