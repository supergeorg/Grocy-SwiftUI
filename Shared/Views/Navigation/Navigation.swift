//
//  Navigation.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.09.23.
//

import SwiftUI

enum NavigationItem: Hashable {
    case quickScan
    case stockOverview
    case stockJournal
    case shoppingList
    case recipes
    case mealPlan
    case choresOverview
    case tasks
    case batteriesOverview
    case equipment
    case calendar
    case purchase
    case consume
    case transfer
    case inventory
    case choreTracking
    case batteryTracking
    case userEntity
    case masterData
    case mdProducts
    case mdLocations
    case mdStores
    case mdQuantityUnits
    case mdProductGroups
    case mdChores
    case mdBatteries
    case mdTaskCategories
    case mdUserFields
    case mdUserEntities
    case settings
    case userManagement
}

struct Navigation: View {
    @Binding var selection: NavigationItem?
    
    var body: some View {
        switch selection ?? .stockOverview {
#if os(iOS)
        case .quickScan:
            QuickScanModeView()
#endif
        case .stockOverview:
            StockView()
        case .stockJournal:
            StockJournalView()
        case .shoppingList:
            ShoppingListView()
        case .recipes:
            RecipesView()
        case .purchase:
            PurchaseProductView()
        case .consume:
            ConsumeProductView()
        case .transfer:
            TransferProductView()
        case .inventory:
            InventoryProductView()
        case .mdProducts:
            MDProductsView()
        case .mdLocations:
            MDLocationsView()
        case .mdStores:
            MDStoresView()
        case .mdQuantityUnits:
            MDQuantityUnitsView()
        case .mdProductGroups:
            MDProductGroupsView()
        case .settings:
            SettingsView()
        case .userManagement:
            UserManagementView()
        default:
            EmptyView()
        }
    }
}

#Preview {
    Navigation(selection: Binding.constant(.stockOverview))
}
