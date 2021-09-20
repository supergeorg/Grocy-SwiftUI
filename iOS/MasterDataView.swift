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
        List(){
            NavigationLink(destination: MDProductsView()) {
                Label(LocalizedStringKey("str.md.products"), systemImage: "archivebox")
            }
            
            NavigationLink(destination: MDLocationsView()) {
                Label(LocalizedStringKey("str.md.locations"), systemImage: MySymbols.location)
            }
            
            NavigationLink(destination: MDShoppingLocationsView()) {
                Label(LocalizedStringKey("str.md.shoppingLocations"), systemImage: MySymbols.shoppingLocation)
            }
            
            NavigationLink(destination: MDQuantityUnitsView()) {
                Label(LocalizedStringKey("str.md.quantityUnits"), systemImage: "number.circle")
            }
            
            NavigationLink(destination: MDProductGroupsView()) {
                Label(LocalizedStringKey("str.md.productGroups"), systemImage: "lessthan.circle")
            }
            
            if devMode {
                NavigationLink(destination: MDChoresView()) {
                    Label(LocalizedStringKey("str.md.chores"), systemImage: "house")
                }
                
                NavigationLink(destination: MDBatteriesView()) {
                    Label(LocalizedStringKey("str.md.batteries"), systemImage: "battery.25")
                }
            }
            NavigationLink(destination: MDTaskCategoriesView()) {
                Label(LocalizedStringKey("str.md.taskCategories"), systemImage: "point.fill.topleft.down.curvedto.point.fill.bottomright.up")
            }
            
            NavigationLink(destination: MDUserFieldsView()) {
                Label(LocalizedStringKey("str.md.userFields"), systemImage: "bookmark.fill")
            }
            
            NavigationLink(destination: MDUserEntitiesView()) {
                Label(LocalizedStringKey("str.md.userEntities"), systemImage: "bookmark")
            }
        }
        .navigationTitle(LocalizedStringKey("str.md.masterData"))
    }
}

struct MasterDataView_Previews: PreviewProvider {
    static var previews: some View {
        MasterDataView()
    }
}
