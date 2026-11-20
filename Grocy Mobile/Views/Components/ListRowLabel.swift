//
//  ListRowLabel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.11.26.
//

import SwiftUI

/// The label of a list row that leads somewhere, with an optional number of items on the trailing side.
///
/// A List tints the icon of a Label that is a row's direct content with the accent color. Here the icon has the text color,
/// like the row's title, so rows of overviews (master data, the settings button's page) look like the system's lists.
struct ListRowLabel: View {
    let title: LocalizedStringKey
    let systemImage: String
    /// Shown when it's greater than zero.
    var count: Int? = nil

    init(_ title: LocalizedStringKey, systemImage: String, count: Int? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.count = count
    }

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundStyle(.primary)
            if let count, count > 0 {
                Spacer()
                Text(count, format: .number)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
    }
}

#Preview {
    NavigationStack {
        List {
            NavigationLink(value: 1) {
                ListRowLabel("Settings", systemImage: MySymbols.settings)
            }
            NavigationLink(value: 2) {
                ListRowLabel("Stores", systemImage: MySymbols.store, count: 3)
            }
        }
    }
}
