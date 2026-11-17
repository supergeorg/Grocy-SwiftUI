//
//  AccountView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 15.11.26.
//

import SwiftData
import SwiftUI

/// Everything that doesn't have a tab of its own on iPhone, opened from the settings button:
/// settings first (always visible without scrolling), the places that aren't tabs (so every complete list stays reachable)
/// and the master data lists, shown directly (one tap instead of two).
///
/// It's pushed onto the current tab instead of shown in a sheet: the master data lists hide their search field
/// above the list until it's pulled down, and in a sheet that pull dismisses the sheet instead.
struct AccountView: View {
    /// Value-based routes, so the master data lists (which navigate by value, too) work inside the same stack.
    enum Route: Hashable {
        case account, settings
    }

    @AppStorage(PhoneNavigationStyle.storageKey) private var style: PhoneNavigationStyle = .smart
    @AppStorage(PhonePlace.tabsStorageKey) private var ownTabs: String = PhonePlace.defaultOwnTabsValue

    @Query private var systemConfigList: [SystemConfig]

    /// The places that aren't tabs in the current style.
    private var otherPlaces: [PhonePlace] {
        let tabs = style == .tabs ? PhonePlace.decode(ownTabs) : PhonePlace.smartTabs
        return PhonePlace.allCases.filter { !tabs.contains($0) && $0.isEnabled(in: systemConfigList.first) }
    }

    var body: some View {
        List {
            Section {
                NavigationLink(value: Route.settings) {
                    Label("Settings", systemImage: MySymbols.settings)
                }
            }
            if style != .sidebar, !otherPlaces.isEmpty {
                Section("More") {
                    ForEach(otherPlaces) { place in
                        NavigationLink(value: place) {
                            Label(place.title, systemImage: place.icon)
                        }
                    }
                }
            }
            Section("Master data") {
                MasterDataLinks()
            }
        }
        .navigationTitle("Grocy Mobile")
    }
}

extension View {
    /// Registers the profile page and its pages, including the master data lists, on a navigation stack's root view.
    /// (Registered on the pushed page itself, the master data destinations aren't found.)
    func accountNavigationDestinations() -> some View {
        masterDataDestinations()
            .navigationDestination(for: AccountView.Route.self) { route in
                switch route {
                case .account:
                    AccountView()
                case .settings:
                    SettingsView()
                }
            }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        AccountView()
            .accountNavigationDestinations()
    }
}
