//
//  MasterDataView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct MasterDataView: View {
    @AppStorage("devMode") private var devMode: Bool = false
    
    var body: some View {
        List {
            NavigationLink(destination: MDProductsView()) {
                Label("Products", systemImage: MySymbols.product)
            }
            
            NavigationLink(destination: MDLocationsView()) {
                Label("Locations", systemImage: MySymbols.location)
            }
            
            NavigationLink(destination: MDStoresView()) {
                Label("Stores", systemImage: MySymbols.store)
            }
            
            NavigationLink(destination: MDQuantityUnitsView()) {
                Label("Quantity units", systemImage: MySymbols.quantityUnit)
            }
            
            NavigationLink(destination: MDProductGroupsView()) {
                Label("Product groups", systemImage: MySymbols.productGroup)
            }
            
            if devMode {
                NavigationLink(destination: MDChoresView()) {
                    Label("Chores", systemImage: "house")
                }
                
                NavigationLink(destination: MDBatteriesView()) {
                    Label("Batteries", systemImage: "battery.25")
                }
                
                NavigationLink(destination: MDTaskCategoriesView()) {
                    Label("Task categories", systemImage: "point.fill.topleft.down.curvedto.point.fill.bottomright.up")
                }
                
                NavigationLink(destination: MDUserFieldsView()) {
                    Label("Userfields", systemImage: "bookmark.fill")
                }
                
                NavigationLink(destination: MDUserEntitiesView()) {
                    Label("User entities", systemImage: "bookmark")
                }
            }
        }
        .navigationTitle("Master data")
    }
}

struct MasterDataView_Previews: PreviewProvider {
    static var previews: some View {
        MasterDataView()
    }
}
