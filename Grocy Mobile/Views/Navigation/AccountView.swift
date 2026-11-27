//
//  AccountView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 15.11.26.
//

import SwiftData
import SwiftUI

/// Everything that doesn't have a tab of its own on iPhone, opened from the settings button:
/// settings first (always visible without scrolling), the places that aren't tabs (so every complete list stays reachable),
/// the master data lists, shown directly (one tap instead of two), and the user management.
///
/// It's pushed onto the current tab instead of shown in a sheet: the master data lists hide their search field
/// above the list until it's pulled down, and in a sheet that pull dismisses the sheet instead.
struct AccountView: View {
    /// Value-based routes, so the master data lists (which navigate by value, too) work inside the same stack.
    enum Route: Hashable {
        case account, settings, userManagement
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
                    ListRowLabel("Settings", systemImage: MySymbols.settings)
                }
            }
            if style != .sidebar, !otherPlaces.isEmpty {
                Section("More") {
                    ForEach(otherPlaces) { place in
                        NavigationLink(value: place) {
                            ListRowLabel(place.title, systemImage: place.icon)
                        }
                    }
                }
            }
            Section("Master data") {
                MasterDataLinks()
            }
            Section {
                NavigationLink(value: Route.userManagement) {
                    ListRowLabel("User management", systemImage: MySymbols.userManagement)
                }
            }
        }
        .navigationTitle("Grocy Mobile")
    }
}

extension View {
    /// Registers the profile page and its pages, including the master data lists, the settings pages and the user form,
    /// on a navigation stack's root view. (Registered on the pushed page itself, these destinations aren't found.)
    func accountNavigationDestinations() -> some View {
        masterDataDestinations()
            .settingsDestinations()
            .userManagementDestinations()
            .navigationDestination(for: AccountView.Route.self) { route in
                switch route {
                case .account:
                    AccountView()
                case .settings:
                    SettingsView(registersDestinations: false)
                case .userManagement:
                    UserManagementView(registersDestinations: false)
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
