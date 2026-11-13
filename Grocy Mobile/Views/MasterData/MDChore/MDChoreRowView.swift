//
//  MDChoreRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 10.12.25.
//

import SwiftUI

struct MDChoreRowView: View {
    var chore: MDChore

    var body: some View {
        VStack(alignment: .leading) {
            Text(chore.name)
                .font(.headline)
                .foregroundStyle(chore.active ? .primary : .secondary)
            // Disabled is spelled out, not only shown by the dimmed color ("Disabled" matches the Grocy web app).
            if !chore.active {
                Text("Disabled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !chore.mdChoreDescription.isEmpty {
                Text(chore.mdChoreDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("\(Text("Period type")): \(Text(chore.periodType.localizedName))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.leading)
        .accessibilityElement(children: .combine)
    }
}
