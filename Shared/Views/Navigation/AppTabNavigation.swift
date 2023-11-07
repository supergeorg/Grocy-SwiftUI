//
//  AppTabNavigation.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

private enum TabNavigationItem: String {
    case quickScanMode = "quickScanMode"
    case stockOverview = "stockOverview"
    case shoppingList = "shoppingList"
    case more = "more"
    case masterData = "masterData"
    case activities = "activities"
    case settings = "settings"
    case openFoodFacts = "openFoodFacts"
    case recipes = "recipes"
}

struct AppTabNavigation: View {
    @AppStorage("tabSelection") private var tabSelection: TabNavigationItem = .stockOverview
    @AppStorage("devMode") private var devMode: Bool = false
    
    var body: some View {
        TabView(selection: $tabSelection) {
            QuickScanModeView()
                .tabItem {
                    Label("Quick Scan", systemImage: MySymbols.barcodeScan)
                }
                .tag(TabNavigationItem.quickScanMode)
            
            NavigationStack {
                StockView()
            }
            .tabItem {
                Label("Stock overview", systemImage: MySymbols.stockOverview)
            }
            .tag(TabNavigationItem.stockOverview)
            
            NavigationStack {
                ShoppingListView()
            }
            .tabItem {
                Label("Shopping list", systemImage: MySymbols.shoppingList)
            }
            .tag(TabNavigationItem.shoppingList)
            
            NavigationStack {
                MasterDataView()
            }
            .tabItem {
                Label("Master data", systemImage: MySymbols.masterData)
            }
            .tag(TabNavigationItem.masterData)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: MySymbols.settings)
            }
            .tag(TabNavigationItem.settings)
        }
    }
}

#Preview {
    AppTabNavigation()
}
