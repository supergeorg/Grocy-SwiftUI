//
//  AccountView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 15.11.26.
//

import SwiftUI

/// Setup that doesn't need a tab of its own on iPhone (iPhone navigation prototype):
/// master data and settings, opened from the profile button.
///
/// It's pushed onto the current tab instead of shown in a sheet: the master data lists hide their search field
/// above the list until it's pulled down, and in a sheet that pull dismisses the sheet instead.
struct AccountView: View {
    /// Value-based routes, so the master data lists (which navigate by value, too) work inside the same stack.
    enum Route: Hashable {
        case account, masterData, settings
    }

    var body: some View {
        List {
            NavigationLink(value: Route.masterData) {
                Label("Master data", systemImage: MySymbols.masterData)
            }
            NavigationLink(value: Route.settings) {
                Label("Settings", systemImage: MySymbols.settings)
            }
        }
        .navigationTitle("Grocy Mobile")
    }
}

extension View {
    /// Registers the profile page and its pages on a navigation stack's root view.
    func accountNavigationDestinations() -> some View {
        navigationDestination(for: AccountView.Route.self) { route in
            switch route {
            case .account:
                AccountView()
            case .masterData:
                MasterDataView()
            case .settings:
                SettingsView()
            }
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        AccountView()
    }
}
