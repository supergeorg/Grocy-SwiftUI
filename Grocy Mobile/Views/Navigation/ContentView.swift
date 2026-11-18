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
        navigation
            .whatsNewSheet()
    }

    @ViewBuilder
    private var navigation: some View {
        #if os(iOS)
            // One branch per navigation, so a size class change that keeps the navigation
            // (opening or closing iPhone Duo, resizing on iPad) keeps its state too.
            if PhoneNavigationStyle.applies(in: horizontalSizeClass) && phoneNavigationStyle != .sidebar {
                // At most five tabs, so iPhone never needs the system "More" list.
                PhoneTabNavigation(places: phoneNavigationStyle == .smart ? PhonePlace.smartTabs : PhonePlace.decode(phoneTabs))
            } else if !PhoneNavigationStyle.applies(in: horizontalSizeClass) && iPadTabNavigation {
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

#Preview(traits: .previewData) {
    ContentView()
}
