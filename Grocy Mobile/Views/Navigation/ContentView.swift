//
//  ContentView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("iPhoneTabNavigation") var iPhoneTabNavigation: Bool = true
    @AppStorage("iPadTabNavigation") var iPadTabNavigation: Bool = false

    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        #if os(iOS)
            if horizontalSizeClass == .compact && iPhoneTabNavigation {
                // Prototype: at most five tabs, so iPhone never needs the system "More" list.
                PhoneTabNavigation()
            } else if iPadTabNavigation {
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
