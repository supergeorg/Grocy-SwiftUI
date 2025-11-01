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
            HStack {
                Text(store.name)
                    .font(.title)
                    .foregroundStyle(store.active ? .primary : .secondary)
                //                if store.hasChanges {
                //                    Image(systemName: MySymbols.notSaved)
                //                        .foregroundStyle(.orange)
                //                }
            }
            if !store.mdStoreDescription.isEmpty {
                Text(store.mdStoreDescription)
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

#Preview {
    MDStoreRowView(store: MDStore(id: 1, name: "Store", active: true, mdStoreDescription: "Description", rowCreatedTimestamp: ""))
}
