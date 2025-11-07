//
//  Sidebar.swift
//  Grocy Mobile (iOS)
//
//  Created by Georg Meissner on 19.09.23.
//

import SwiftUI

struct Sidebar: View {
    @Binding var selection: NavigationItem?

    @AppStorage("devMode") private var devMode: Bool = false

    @State private var isMasterDataSectionExpanded: Bool = false

    var body: some View {
        List(selection: $selection) {
            Section {
                #if os(iOS)
                    NavigationLink(value: NavigationItem.quickScan) {
                        Label("Quick-Scan", systemImage: MySymbols.barcodeScan)
                    }
                #endif
                NavigationLink(value: NavigationItem.stockOverview) {
                    Label("Stock overview", systemImage: MySymbols.stockOverview)
                }
                NavigationLink(value: NavigationItem.stockJournal) {
                    Label("Stock journal", systemImage: MySymbols.stockJournal)
                }
                NavigationLink(value: NavigationItem.shoppingList) {
                    Label("Shopping list", systemImage: MySymbols.shoppingList)
                }
            }

            if devMode {
                Section {
                    NavigationLink(value: NavigationItem.recipes) {
                        Label("Recipes", systemImage: MySymbols.recipe)
                    }
                    NavigationLink(value: NavigationItem.mealPlan) {
                        Label("Meal plan", systemImage: MySymbols.date)
                    }
                }
            }

            if devMode {
                Section {
                    NavigationLink(value: NavigationItem.choresOverview) {
                        Label("Chores overview", systemImage: MySymbols.chores)
                    }
                    NavigationLink(value: NavigationItem.tasks) {
                        Label("Tasks", systemImage: MySymbols.tasks)
                    }
                    NavigationLink(value: NavigationItem.batteriesOverview) {
                        Label("Batteries overview", systemImage: MySymbols.batteries)
                    }
                    NavigationLink(value: NavigationItem.equipment) {
                        Label("Equipment", systemImage: "questionmark")
                    }
                }
            }

            if devMode {
                Section {
                    NavigationLink(value: NavigationItem.calendar) {
                        Label("Calendar", systemImage: MySymbols.date)
                    }
                }
            }

            Section {
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
                if devMode {
                    NavigationLink(value: NavigationItem.choreTracking) {
                        Label("Chore tracking", systemImage: MySymbols.chores)
                    }
                    NavigationLink(value: NavigationItem.batteryTracking) {
                        Label("Battery tracking", systemImage: MySymbols.batteries)
                    }
                }
            }

            Section(
                isExpanded: $isMasterDataSectionExpanded,
                content: {
                    NavigationLink(value: NavigationItem.mdProducts) {
                        Label("Products", systemImage: MySymbols.product)
                    }
                    NavigationLink(value: NavigationItem.mdLocations) {
                        Label("Locations", systemImage: MySymbols.location)
                    }
                    NavigationLink(value: NavigationItem.mdStores) {
                        Label("Stores", systemImage: MySymbols.store)
                    }
                    NavigationLink(value: NavigationItem.mdQuantityUnits) {
                        Label("Quantity units", systemImage: MySymbols.quantityUnit)
                    }
                    NavigationLink(value: NavigationItem.mdProductGroups) {
                        Label("Product groups", systemImage: MySymbols.productGroup)
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
