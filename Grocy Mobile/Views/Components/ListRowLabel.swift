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
    private let title: Text
    /// A second line below the title, in the secondary style. With it, the title is a headline, like the app's other
    /// two-line rows (stock, master data).
    private let subtitle: LocalizedStringKey?
    private let systemImage: String
    /// Shown when it's greater than zero.
    private let count: Int?

    /// Like `Label`, a localized title.
    init(_ titleKey: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, systemImage: String, count: Int? = nil) {
        self.init(title: Text(titleKey), subtitle: subtitle, systemImage: systemImage, count: count)
    }

    /// Like `Label`, a title shown as it is, for names from the server, which aren't in the string catalog.
    init<S: StringProtocol>(_ title: S, subtitle: LocalizedStringKey? = nil, systemImage: String, count: Int? = nil) {
        self.init(title: Text(title), subtitle: subtitle, systemImage: systemImage, count: count)
    }

    private init(title: Text, subtitle: LocalizedStringKey?, systemImage: String, count: Int?) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.count = count
    }

    var body: some View {
        HStack {
            Label {
                if let subtitle {
                    VStack(alignment: .leading) {
                        title
                            .font(.headline)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    title
                }
            } icon: {
                Image(systemName: systemImage)
            }
            .foregroundStyle(.primary)
            if let count, count > 0 {
                Spacer()
                Text(count, format: .number)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
        // Read as one element: the title, the subtitle and the count.
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    // A name from the server.
    let verbatim = "Fridge"
    NavigationStack {
        List {
            NavigationLink(value: 1) {
                ListRowLabel("Settings", systemImage: MySymbols.settings)
            }
            NavigationLink(value: 2) {
                ListRowLabel("Stores", systemImage: MySymbols.store, count: 3)
            }
            NavigationLink(value: 3) {
                ListRowLabel(verbatim, subtitle: "Location", systemImage: MySymbols.location)
            }
        }
    }
}
