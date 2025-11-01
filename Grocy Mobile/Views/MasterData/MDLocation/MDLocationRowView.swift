//
//  MDLocationRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 19.10.23.
//

// import SwiftData
import SwiftUI

struct MDLocationRowView: View {
    var location: MDLocation

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text(location.name)
                    .font(.title)
                    .foregroundStyle(location.active ? .primary : .secondary)
                //                if location.hasChanges {
                //                    Image(systemName: MySymbols.notSaved)
                //                        .foregroundStyle(.orange)
                //                }
                if location.isFreezer {
                    Image(systemName: MySymbols.freezing)
                        .font(.title)
                }
            }
            if !location.mdLocationDescription.isEmpty {
                Text(location.mdLocationDescription)
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

#Preview {
    MDLocationRowView(location: MDLocation(id: 1, name: "Location", active: true, mdLocationDescription: "Description", isFreezer: true, rowCreatedTimestamp: ""))
}
