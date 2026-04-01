//
//  Sidebar.swift
//  Grocy Mobile (iOS)
//
//  Created by Georg Meissner on 19.09.23.
//

import SwiftData
import SwiftUI

struct Sidebar: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Binding var selection: NavigationItem?

    @AppStorage("devMode") private var devMode: Bool = false

    @State private var isMasterDataSectionExpanded: Bool = false

    @Query var systemConfigList: [SystemConfig]
    var systemConfig: SystemConfig? {
        systemConfigList.first
    }

    var body: some View {
        List(selection: $selection) {
            Section {
                #if os(iOS)
                    NavigationLink(value: NavigationItem.quickScan) {
                        Label("Quick Scan", systemImage: MySymbols.barcodeScan)
                    }
                #endif
                if !(systemConfig?.featureFlagStock == false) {
                    NavigationLink(value: NavigationItem.stockOverview) {
                        Label("Stock overview", systemImage: MySymbols.stockOverview)
                    }
                }
                if !(systemConfig?.featureFlagShoppinglist == false) {
                    NavigationLink(value: NavigationItem.shoppingList) {
                        Label("Shopping list", systemImage: MySymbols.shoppingList)
                    }
                }
            }

            Section {
                if !(systemConfig?.featureFlagRecipes == false) {
                    NavigationLink(value: NavigationItem.recipes) {
                        Label("Recipes", systemImage: MySymbols.recipe)
                    }

                    if devMode {
                        NavigationLink(value: NavigationItem.mealPlan) {
                            Label("Meal plan", systemImage: MySymbols.date)
                        }
                    }
                }
            }

            Section {
                if !(systemConfig?.featureFlagChores == false) {
                    NavigationLink(value: NavigationItem.choresOverview) {
                        Label("Chores overview", systemImage: MySymbols.chores)
                    }
                }
                if !(systemConfig?.featureFlagTasks == false) {
                    NavigationLink(value: NavigationItem.tasks) {
                        Label("Tasks", systemImage: MySymbols.tasks)
                    }
                }
                if devMode {
                    if !(systemConfig?.featureFlagBatteries == false) {
                        NavigationLink(value: NavigationItem.batteriesOverview) {
                            Label("Batteries overview", systemImage: MySymbols.batteries)
                        }
                    }
                    if !(systemConfig?.featureFlagEquipment == false) {
                        NavigationLink(value: NavigationItem.equipment) {
                            Label("Equipment", systemImage: "questionmark")
                        }
                    }
                }
            }

            if devMode {
                Section {
                    if !(systemConfig?.featureFlagCalendar == false) {
                        NavigationLink(value: NavigationItem.calendar) {
                            Label("Calendar", systemImage: MySymbols.date)
                        }
                    }
                }
            }

            Section {
                if !(systemConfig?.featureFlagStock == false) {
                    NavigationLink(value: NavigationItem.purchase) {
                        Label("Purchase", systemImage: MySymbols.purchase)
                    }
                    NavigationLink(value: NavigationItem.consume) {
                        Label("Consume", systemImage: MySymbols.consume)
                    }
                    NavigationLink(value: NavigationItem.transfer) {
                        Label("Transfer", systemImage: MySymbols.transfer)
                    }
                    NavigationLink(value: NavigationItem.inventory) {
                        Label("Inventory", systemImage: MySymbols.inventory)
                    }
                }
                if !(systemConfig?.featureFlagChores == false) {
                    NavigationLink(value: NavigationItem.choreTracking) {
                        Label("Chore tracking", systemImage: MySymbols.chores)
                    }
                }
                if devMode {
                    if !(systemConfig?.featureFlagBatteries == false) {
                        NavigationLink(value: NavigationItem.batteryTracking) {
                            Label("Battery tracking", systemImage: MySymbols.batteries)
                        }
                    }
                }
            }

            Section(
                isExpanded: $isMasterDataSectionExpanded,
                content: {
                    NavigationLink(value: NavigationItem.mdProducts) {
                        MDCategoryRowView(categoryName: "Products", iconName: MySymbols.product, mdType: MDProduct.self)
                    }
                    if !(systemConfig?.featureFlagStock == false) {
                        NavigationLink(value: NavigationItem.mdLocations) {
                            MDCategoryRowView(categoryName: "Locations", iconName: MySymbols.location, mdType: MDLocation.self)
                        }
                        NavigationLink(value: NavigationItem.mdStores) {
                            MDCategoryRowView(categoryName: "Stores", iconName: MySymbols.store, mdType: MDStore.self)
                        }
                    }
                    NavigationLink(value: NavigationItem.mdQuantityUnits) {
                        MDCategoryRowView(categoryName: "Quantity units", iconName: MySymbols.quantityUnit, mdType: MDQuantityUnit.self)
                    }
                    NavigationLink(value: NavigationItem.mdProductGroups) {
                        MDCategoryRowView(categoryName: "Product groups", iconName: MySymbols.productGroup, mdType: MDProductGroup.self)
                    }
                    if !(systemConfig?.featureFlagChores == false) {
                        NavigationLink(value: NavigationItem.mdChores) {
                            MDCategoryRowView(categoryName: "Chores", iconName: MySymbols.chores, mdType: MDChore.self)
                        }
                    }
                    if devMode {
                        if !(systemConfig?.featureFlagBatteries == false) {
                            NavigationLink(value: NavigationItem.mdBatteries) {
                                MDCategoryRowView(categoryName: "Batteries", iconName: MySymbols.batteries, mdType: MDBattery.self)
                            }
                        }
                    }
                    if !(systemConfig?.featureFlagTasks == false) {
                        NavigationLink(value: NavigationItem.mdTaskCategories) {
                            MDCategoryRowView(categoryName: "Task categories", iconName: MySymbols.tasks, mdType: MDTaskCategory.self)
                        }
                    }
                },
                header: {
                    Label("Master data", systemImage: MySymbols.masterData)
                }
            )

            if devMode {
                NavigationLink(
                    value: NavigationItem.userManagement,
                    label: {
                        Label("User management", systemImage: MySymbols.user)
                    }
                )

                NavigationLink(
                    value: NavigationItem.recipeParsing,
                    label: {
                        Label("Recipe parsing", systemImage: MySymbols.recipe)
                    }
                )
            }

            #if os(iOS)
                NavigationLink(value: NavigationItem.settings) {
                    Label("Settings", systemImage: MySymbols.settings)
                }
            #endif
        }
        #if os(iOS)
            .toolbar(content: {
                ToolbarItem(
                    placement: .topBarLeading,
                    content: {
                        Image("grocy-logo")
                            .resizable()
                            .scaledToFit()
                    }
                )
            })
        #endif
        #if os(macOS)
            .navigationSplitViewColumnWidth(min: 200, ideal: 200)
        #endif
    }
}

#Preview {
    Sidebar(selection: Binding.constant(.stockOverview))
}
