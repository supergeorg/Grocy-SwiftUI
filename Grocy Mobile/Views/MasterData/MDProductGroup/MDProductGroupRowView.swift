//
//  MDProductGroupRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 19.10.23.
//

import SwiftData
import SwiftUI

struct MDProductGroupRowView: View {
    var productGroup: MDProductGroup

    var body: some View {
        VStack(alignment: .leading) {
            Text(productGroup.name)
                .font(.headline)
                .foregroundStyle(productGroup.active ? .primary : .secondary)
            // Disabled is spelled out, not only shown by the dimmed color ("Disabled" matches the Grocy web app).
            if !productGroup.active {
                Text("Disabled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !productGroup.mdProductGroupDescription.isEmpty {
                Text(productGroup.mdProductGroupDescription)
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
        MDProductGroupRowView(productGroup: MDProductGroup(id: 1, name: "Product group"))
    }
}
