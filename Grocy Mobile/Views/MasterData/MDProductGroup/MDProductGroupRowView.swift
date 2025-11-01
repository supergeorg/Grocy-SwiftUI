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
            HStack {
                Text(productGroup.name)
                    .font(.title)
                    .foregroundColor(productGroup.active ? .primary : .gray)
                //                if productGroup.hasChanges {
                //                    Image(systemName: MySymbols.notSaved)
                //                        .foregroundStyle(.orange)
                //                }
            }
            if !productGroup.mdProductGroupDescription.isEmpty {
                Text(productGroup.mdProductGroupDescription)
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

#Preview {
    MDProductGroupRowView(productGroup: MDProductGroup(id: 1, name: "Product group", active: true, rowCreatedTimestamp: ""))
}
