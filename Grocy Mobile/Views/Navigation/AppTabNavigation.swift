//
//  AppTabNavigation.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

private enum TabNavigationItem: String, Codable {
    case quickScanMode = "quickScanMode"
    case stockOverview = "stockOverview"
    case stockJournal = "stockJournal"
    case shoppingList = "shoppingList"
    case more = "more"
    case masterData = "masterData"
    case activities = "activities"
    case settings = "settings"
    case openFoodFacts = "openFoodFacts"
    case recipes = "recipes"
    case stockInteraction = "stockInteraction"
    case purchaseProduct = "purchaseProduct"
    case consumeProduct = "consumeProduct"
    case transferProduct = "transferProduct"
    case inventoryProduct = "inventoryProduct"
    case mdProducts = "mdProducts"
    case mdLocations = "mdLocations"
    case mdStores = "mdStores"
    case mdQuantityUnits = "mdQuantityUnits"
    case mdProductGroups = "mdProductGroups"
}

struct AppTabNavigation: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @AppStorage("tabSelection") private var tabSelection: TabNavigationItem = .stockOverview
    @AppStorage("devMode") private var devMode: Bool = false

    var body: some View {
        TabView(selection: $tabSelection) {
            Tab("Quick Scan", systemImage: MySymbols.barcodeScan, value: TabNavigationItem.quickScanMode) {
                NavigationStack {
                    QuickScanModeView()
                }
            }

            Tab("Stock", systemImage: MySymbols.stockOverview, value: TabNavigationItem.stockOverview) {
                NavigationStack {
                    StockView()
                }
            }

            Tab("Stock journal", systemImage: MySymbols.stockJournal, value: TabNavigationItem.stockJournal) {
                StockJournalView()
            }
            .hidden(sizeClass == .compact)

            Tab("Shopping list", systemImage: MySymbols.shoppingList, value: TabNavigationItem.shoppingList) {
                NavigationStack {
                    ShoppingListView()
                }
            }

            if devMode {
                Tab("Recipes", systemImage: MySymbols.recipe, value: TabNavigationItem.recipes) {
                    NavigationStack {
                        RecipesView()
                    }
                }
            }

            TabSection(
                "Stock interaction",
                content: {
                    Tab("Purchase", systemImage: MySymbols.purchase, value: TabNavigationItem.purchaseProduct) {
                        PurchaseProductView()
                    }
                    Tab("Consume", systemImage: MySymbols.consume, value: TabNavigationItem.consumeProduct) {
                        ConsumeProductView()
                    }
                    Tab("Transfer", systemImage: MySymbols.transfer, value: TabNavigationItem.transferProduct) {
                        TransferProductView()
                    }
                    Tab("Inventory", systemImage: MySymbols.inventory, value: TabNavigationItem.inventoryProduct) {
                        InventoryProductView()
                    }
                }
            )
            .hidden(sizeClass == .compact)

            TabSection(
                "Master data",
                content: {
                    Tab("Products", systemImage: MySymbols.product, value: TabNavigationItem.mdProducts) {
                        MDProductsView()
                    }
                    Tab("Locations", systemImage: MySymbols.location, value: TabNavigationItem.mdLocations) {
                        MDLocationsView()
                    }
                    Tab("Stores", systemImage: MySymbols.store, value: TabNavigationItem.mdStores) {
                        MDStoresView()
                    }
                    Tab("Quantity units", systemImage: MySymbols.quantityUnit, value: TabNavigationItem.mdQuantityUnits) {
                        MDQuantityUnitsView()
                    }
                    Tab("Product groups", systemImage: MySymbols.productGroup, value: TabNavigationItem.mdProductGroups) {
                        MDProductGroupsView()
                    }
                }
            )
            .hidden(sizeClass == .compact)

            Tab("Master data", systemImage: MySymbols.masterData, value: TabNavigationItem.masterData) {
                NavigationStack {
                    MasterDataView()
                }
            }
            .hidden(sizeClass != .compact)
            #if os(iOS)
                Tab("Settings", systemImage: MySymbols.settings, value: TabNavigationItem.settings) {
                    NavigationStack {
                        SettingsView()
                    }
                }
            #endif
        }
        .tabViewStyle(.sidebarAdaptable)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Image("grocy-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 32)
            }
        }
        #if os(iOS)
            .tabBarMinimizeBehavior(.onScrollDown)
        #endif
    }
}

#Preview {
    AppTabNavigation()
}
