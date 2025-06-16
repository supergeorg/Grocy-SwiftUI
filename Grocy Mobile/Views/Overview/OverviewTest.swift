//
//  OverviewTest.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 13.10.23.
//

import SwiftUI

struct OverviewTest: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    var body: some View {
        List {
            Section {
                VStack {
                    HStack {
                        NavigationLink(value: NavigationItem.stockOverview) {
                            OverviewCard(title: "Stock overview", highlightColor: Color.blue, icon: MySymbols.stockOverview, number: grocyVM.stock.count, selected: false)
                        }
                        NavigationLink(value: NavigationItem.shoppingList) {
                            OverviewCard(title: "Shopping list", highlightColor: Color.red, icon: MySymbols.shoppingList, number: nil, selected: false)
                        }
                    }
                    HStack {
                        NavigationLink(value: NavigationItem.recipes) {
                            OverviewCard(title: "Recipes", highlightColor: Color.yellow, icon: MySymbols.recipe, number: nil, selected: false)
                        }
                    }
                }
            }
//            .listStyle(.insetGrouped)
            
//            Section {
//                NavigationLink("Purchase", value: NavigationItem.purchase)
//                NavigationLink("Consume", value: NavigationItem.consume)
//                NavigationLink("Transfer", value: NavigationItem.transfer)
//                NavigationLink("Inventory", value: NavigationItem.inventory)
//            }
        }
        .navigationDestination(for: NavigationItem.self, destination: { navigationItem in
            switch navigationItem {
            case .stockOverview:
                StockView()
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
            default:
                EmptyView()
            }
        })
    }
}

#Preview {
    OverviewTest()
}
