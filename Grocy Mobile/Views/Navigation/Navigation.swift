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
    case recipeParsing
}

struct Navigation: View {
    @Binding var selection: NavigationItem?

    var body: some View {
        switch selection ?? .stockOverview {
        case .quickScan:
            QuickScanModeView()
        case .stockOverview:
            StockView()
        case .shoppingList:
            ShoppingListView()
        case .recipes:
            RecipesView()
        case .mealPlan:
            EmptyView()
        case .choresOverview:
            ChoresView()
        case .tasks:
            TasksView()
        case .batteriesOverview:
            BatteriesView()
        case .equipment:
            EquipmentView()
        case .calendar:
            EmptyView()
        case .purchase:
            PurchaseProductView()
        case .consume:
            ConsumeProductView()
        case .transfer:
            TransferProductView()
        case .inventory:
            InventoryProductView()
        case .choreTracking:
            ChoreTrackingView()
        case .batteryTracking:
            BatteryTrackingView()
        case .userEntity:
            EmptyView()
        case .masterData:
            MasterDataView()
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
        case .mdChores:
            MDChoresView()
        case .mdBatteries:
            MDBatteriesView()
        case .mdTaskCategories:
            MDTaskCategoriesView()
        case .settings:
            SettingsView()
        case .userManagement:
            UserManagementView()
        case .mdUserFields:
            MDUserFieldsView()
        case .mdUserEntities:
            MDUserEntitiesView()
        case .recipeParsing:
            RecipeParserView()
        }
    }
}

#Preview {
    NavigationStack {
        Navigation(selection: Binding.constant(.settings))
    }
}
