//
//  MasterDataView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftData
import SwiftUI

enum MasterDataItem: Hashable {
    case products
    case locations
    case stores
    case quantityUnits
    case productGroups
    case chores
    case batteries
    case taskCategories
    case userFields
    case userEntities
}

/// The master data lists, as list rows. Used by `MasterDataView` and directly on the iPhone's `AccountView`
/// (so master data is one tap away). Needs `masterDataDestinations()` on the navigation stack.
struct MasterDataLinks: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.grocyFeatures) private var features

    @Query var systemConfigList: [SystemConfig]
    var systemConfig: SystemConfig? {
        systemConfigList.first
    }

    var body: some View {
        NavigationLink(value: MasterDataItem.products) {
            MDCategoryRowView(categoryName: "Products", iconName: MySymbols.product, mdType: MDProduct.self)
        }

        if !(systemConfig?.featureFlagStock == false) && features.locationTracking {
            NavigationLink(value: MasterDataItem.locations) {
                MDCategoryRowView(categoryName: "Locations", iconName: MySymbols.location, mdType: MDLocation.self)
            }
        }

        if !(systemConfig?.featureFlagStock == false) {
            NavigationLink(value: MasterDataItem.stores) {
                MDCategoryRowView(categoryName: "Stores", iconName: MySymbols.store, mdType: MDStore.self)
            }
        }

        NavigationLink(value: MasterDataItem.quantityUnits) {
            MDCategoryRowView(categoryName: "Quantity units", iconName: MySymbols.quantityUnit, mdType: MDQuantityUnit.self)
        }

        NavigationLink(value: MasterDataItem.productGroups) {
            MDCategoryRowView(categoryName: "Product groups", iconName: MySymbols.productGroup, mdType: MDProductGroup.self)
        }

        if !(systemConfig?.featureFlagChores == false) {
            NavigationLink(value: MasterDataItem.chores) {
                MDCategoryRowView(categoryName: "Chores", iconName: MySymbols.chores, mdType: MDChore.self)
            }
        }

        if !(systemConfig?.featureFlagBatteries == false) {
            NavigationLink(value: MasterDataItem.batteries) {
                MDCategoryRowView(categoryName: "Batteries", iconName: MySymbols.batteries, mdType: MDBattery.self)
            }
        }

        if !(systemConfig?.featureFlagTasks == false) {
            NavigationLink(value: MasterDataItem.taskCategories) {
                MDCategoryRowView(categoryName: "Task categories", iconName: MySymbols.tasks, mdType: MDTaskCategory.self)
            }
        }

        NavigationLink(value: MasterDataItem.userFields) {
            ListRowLabel("Userfields", systemImage: MySymbols.userfields, count: grocyVM.mdUserFields.count)
        }
        // Userfields and user entities are only kept in memory, so they are loaded for their counts.
        .task {
            await grocyVM.requestData(objects: [.userfields, .userentities])
        }

        NavigationLink(value: MasterDataItem.userEntities) {
            ListRowLabel("User entities", systemImage: MySymbols.userEntities, count: grocyVM.mdUserEntities.count)
        }
    }
}

extension View {
    /// Registers the master data lists (`MasterDataLinks`) on a navigation stack.
    func masterDataDestinations() -> some View {
        navigationDestination(for: MasterDataItem.self) { masterDataItem in
            switch masterDataItem {
            case .products:
                MDProductsView()
            case .locations:
                MDLocationsView()
            case .stores:
                MDStoresView()
            case .quantityUnits:
                MDQuantityUnitsView()
            case .productGroups:
                MDProductGroupsView()
            case .chores:
                MDChoresView()
            case .batteries:
                MDBatteriesView()
            case .taskCategories:
                MDTaskCategoriesView()
            case .userFields:
                MDUserFieldsView()
            case .userEntities:
                MDUserEntitiesView()
            }
        }
    }
}

struct MasterDataView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var body: some View {
        List {
            MasterDataLinks()
        }
        .navigationTitle("Master data")
        .masterDataDestinations()
        .task {
            await grocyVM.requestData(additionalObjects: [.system_config])
        }
    }
}

#Preview {
    NavigationStack {
        MasterDataView()
    }
}
