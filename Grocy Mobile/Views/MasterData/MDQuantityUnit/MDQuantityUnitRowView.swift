//
//  MDQuantityUnitRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 19.10.23.
//

//import SwiftData
import SwiftUI

struct MDQuantityUnitRowView: View {
    var quantityUnit: MDQuantityUnit

    var body: some View {
        HStack(alignment: .center) {
            Text(quantityUnit.name)
                .font(.title)
            if !quantityUnit.namePlural.isEmpty {
                Text("(\(quantityUnit.namePlural))")
                    .font(.title3)
            }
            //            if quantityUnit.hasChanges {
            //                Image(systemName: MySymbols.notSaved)
            //                    .foregroundStyle(.orange)
            //            }
        }
        .foregroundStyle(quantityUnit.active ? .primary : .secondary)
        if !quantityUnit.mdQuantityUnitDescription.isEmpty {
            Text(quantityUnit.mdQuantityUnitDescription)
                .font(.caption)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    MDQuantityUnitRowView(quantityUnit: MDQuantityUnit(id: 1, name: "Quantity unit", namePlural: "Quantity units", active: true, mdQuantityUnitDescription: "Description", rowCreatedTimestamp: ""))
}
