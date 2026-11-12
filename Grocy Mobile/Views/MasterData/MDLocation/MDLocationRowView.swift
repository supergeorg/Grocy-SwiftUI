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
            HStack(alignment: .firstTextBaseline) {
                Text(location.name)
                    .font(.headline)
                    .foregroundStyle(location.active ? .primary : .secondary)
                if location.isFreezer {
                    Image(systemName: MySymbols.freezing)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(Text("Freezer"))
                }
            }
            // Disabled is spelled out, not only shown by the dimmed color ("Disabled" matches the Grocy web app).
            if !location.active {
                Text("Disabled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !location.mdLocationDescription.isEmpty {
                Text(location.mdLocationDescription)
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
        MDLocationRowView(location: MDLocation(id: 1, name: "Location", active: true, mdLocationDescription: "Description", isFreezer: false))
        MDLocationRowView(location: MDLocation(id: 2, name: "Freezer", active: true, mdLocationDescription: "Description", isFreezer: true))
        MDLocationRowView(location: MDLocation(id: 3, name: "Cellar", active: false, mdLocationDescription: "", isFreezer: false))
    }
}
