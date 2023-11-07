//
//  ContentView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("iPhoneTabNavigation") var iPhoneTabNavigation: Bool = false
    
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif
    
    var body: some View {
#if os(iOS)
        if horizontalSizeClass == .compact && iPhoneTabNavigation {
            AppTabNavigation()
        } else {
            AppSidebarNavigation()
        }
#elseif os(macOS)
        AppSidebarNavigation()
            .frame(minWidth: 500)
#endif
    }
}

#Preview {
    ContentView()
}
