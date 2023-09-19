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
                Label("str.nav.quickScan", systemImage: MySymbols.barcodeScan)
            }
#endif
            NavigationLink(value: NavigationItem.stockOverview) {
                Label("str.nav.stockOverview", systemImage: MySymbols.stockOverview)
            }
            NavigationLink(value: NavigationItem.shoppingList) {
                Label("str.nav.shoppingList", systemImage: MySymbols.shoppingList)
            }
            
            Divider()
            
            NavigationLink(value: NavigationItem.purchase) {
                Label("str.nav.purchase", systemImage: MySymbols.purchase)
            }
            NavigationLink(value: NavigationItem.consume) {
                Label("str.nav.consume", systemImage: MySymbols.consume)
            }
            NavigationLink(value: NavigationItem.transfer) {
                Label("str.nav.transfer", systemImage: MySymbols.transfer)
            }
            NavigationLink(value: NavigationItem.inventory) {
                Label("str.nav.inventory", systemImage: MySymbols.inventory)
            }
            
            Section(isExpanded: $isMasterDataSectionExpanded, content: {
                NavigationLink(value: NavigationItem.mdProducts) {
                    Label("str.nav.md.products", systemImage: MySymbols.product)
                }
                NavigationLink(value: NavigationItem.mdLocations) {
                    Label("str.nav.md.locations", systemImage: MySymbols.location)
                }
                NavigationLink(value: NavigationItem.mdStores) {
                    Label("str.nav.md.stores", systemImage: MySymbols.store)
                }
                NavigationLink(value: NavigationItem.mdQuantityUnits) {
                    Label("str.nav.md.quantityUnits", systemImage: MySymbols.quantityUnit)
                }
                NavigationLink(value: NavigationItem.mdProductGroups) {
                    Label("str.nav.md.productGroups", systemImage: MySymbols.productGroup)
                }
            }, header: {
                Label("str.nav.md", systemImage: MySymbols.masterData)
            })
            
#if os(iOS)
            NavigationLink(value: NavigationItem.settings) {
                Label("str.nav.settings", systemImage: MySymbols.settings)
            }
#endif
        }
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading, content: {
                Image("grocy-logo")
                    .resizable()
                    .scaledToFit()
            })
        })
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 200, ideal: 200)
#endif
    }
}

#Preview {
    Sidebar(selection: Binding.constant(.stockOverview))
}
