//
//  ContentView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct ContentView: View {
    @AppStorage(PhoneNavigationStyle.storageKey) var phoneNavigationStyle: PhoneNavigationStyle = .smart
    @AppStorage(PhonePlace.tabsStorageKey) var phoneTabs: String = PhonePlace.defaultOwnTabsValue
    @AppStorage("iPadTabNavigation") var iPadTabNavigation: Bool = false

    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        #if os(iOS)
            if horizontalSizeClass == .compact && phoneNavigationStyle != .sidebar {
                // At most five tabs, so iPhone never needs the system "More" list.
                PhoneTabNavigation(places: phoneNavigationStyle == .smart ? PhonePlace.smartTabs : PhonePlace.decode(phoneTabs))
            } else if horizontalSizeClass != .compact && iPadTabNavigation {
                AppTabNavigation()
            } else {
                AppSidebarNavigation()
            }
        #elseif os(macOS)
            AppSidebarNavigation()
                .frame(minWidth: Constants.macOSMinWindowWidth)
        #endif
    }
}

#Preview {
    ContentView()
}
