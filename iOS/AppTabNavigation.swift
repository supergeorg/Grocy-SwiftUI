//
//  AppTabNavigation.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

extension AppTabNavigation {
    private enum Tab: String {
        case stockOverview = "books.vertical"
        case shoppingList = "cart"
        case more = "ellipsis.circle"
        case masterData = "text.book.closed"
        case settings = "gear"
    }
}

struct AppTabNavigation: View {
    @State private var selection: Tab = .settings
    
    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                StockView()
            }
            .tabItem {
                Label("str.nav.stockOverview", systemImage: Tab.stockOverview.rawValue)
                    .accessibility(label: Text("str.nav.stockOverview"))
            }
            .tag(Tab.stockOverview)
            
//            NavigationView {
//                EmptyView()
//            }
//            .tabItem {
//                Label("str.nav.shoppingList", systemImage: Tab.shoppingList.rawValue)
//                    .accessibility(label: Text("str.nav.shoppingList"))
//            }
//            .tag(Tab.shoppingList)
//            
            NavigationView {
                MasterDataView()
            }
            .tabItem {
                Label("str.nav.md", systemImage: Tab.masterData.rawValue)
                    .accessibility(label: Text("str.nav.md"))
            }
            .tag(Tab.masterData)
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("str.nav.settings", systemImage: Tab.settings.rawValue)
                    .accessibility(label: Text("str.nav.settings"))
            }
            .tag(Tab.settings)
            
        }
//        Text("Hi")
    }
}

struct AppTabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        AppTabNavigation()
    }
}
