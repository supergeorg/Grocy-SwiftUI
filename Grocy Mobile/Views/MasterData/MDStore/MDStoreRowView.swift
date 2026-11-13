//
//  MDStoreRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 19.10.23.
//

//import SwiftData
import SwiftUI

struct MDStoreRowView: View {
    var store: MDStore

    var body: some View {
        VStack(alignment: .leading) {
            Text(store.name)
                .font(.headline)
                .foregroundStyle(store.active ? .primary : .secondary)
            // Disabled is spelled out, not only shown by the dimmed color ("Disabled" matches the Grocy web app).
            if !store.active {
                Text("Disabled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !store.mdStoreDescription.isEmpty {
                Text(store.mdStoreDescription)
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
        MDStoreRowView(store: MDStore(id: 1, name: "Store", mdStoreDescription: "Description"))
    }
}
