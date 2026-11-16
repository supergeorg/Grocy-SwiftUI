//
//  MasterDataView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftData
import SwiftUI

private enum MasterDataItem: Hashable {
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

struct MasterDataView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @AppStorage("devMode") private var devMode: Bool = false

    @Query var systemConfigList: [SystemConfig]
    var systemConfig: SystemConfig? {
        systemConfigList.first
    }

    var body: some View {
        List {
            NavigationLink(value: MasterDataItem.products) {
                MDCategoryRowView(categoryName: "Products", iconName: MySymbols.product, mdType: MDProduct.self)
            }

            if !(systemConfig?.featureFlagStock == false) {
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

            if devMode {
                NavigationLink(value: MasterDataItem.userFields) {
                    Label("Userfields", systemImage: MySymbols.unknown)
                }

                NavigationLink(value: MasterDataItem.userEntities) {
                    Label("User entities", systemImage: MySymbols.unknown)
                }
            }
        }
        .navigationTitle("Master data")
        .navigationDestination(
            for: MasterDataItem.self,
            destination: { masterDataItem in
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
        )
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
