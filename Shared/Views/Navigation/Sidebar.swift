//
//  Sidebar.swift
//  Grocy Mobile (iOS)
//
//  Created by Georg Meissner on 19.09.23.
//

import SwiftUI

struct Sidebar: View {
    @Binding var selection: NavigationItem?
    
    @State private var isMasterDataSectionExpanded: Bool = false
    
    var body: some View {
        List(selection: $selection) {
#if os(iOS)
            NavigationLink(value: NavigationItem.quickScan) {
                Label("Quick-Scan", systemImage: MySymbols.barcodeScan)
            }
#endif
            NavigationLink(value: NavigationItem.stockOverview) {
                Label("Stock overview", systemImage: MySymbols.stockOverview)
            }
            NavigationLink(value: NavigationItem.shoppingList) {
                Label("Shopping list", systemImage: MySymbols.shoppingList)
            }
            
            Divider()
            
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
            
            Section(isExpanded: $isMasterDataSectionExpanded, content: {
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
            }, header: {
                Label("Master data", systemImage: MySymbols.masterData)
            })
            
//#if os(iOS)
            NavigationLink(value: NavigationItem.settings) {
                Label("Settings", systemImage: MySymbols.settings)
            }
//#endif
        }
#if os(iOS)
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading, content: {
                Image("grocy-logo")
                    .resizable()
                    .scaledToFit()
            })
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
