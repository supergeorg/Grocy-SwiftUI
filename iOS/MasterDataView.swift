//
//  MasterDataView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct MasterDataView: View {
    var body: some View {
        List(){
            NavigationLink(destination: MDProductsView()) {
                HStack{
                    Image(systemName: "archivebox")
                    Text("str.md.products")
                }
            }
            NavigationLink(destination: MDLocationsView()) {
                HStack{
                    Image(systemName: "location")
                    Text("str.md.locations")
                }
            }
            NavigationLink(destination: MDShoppingLocationsView()) {
                HStack{
                    Image(systemName: "cart")
                    Text("str.md.shoppingLocations")
                }
            }
            NavigationLink(destination: MDQuantityUnitsView()) {
                HStack{
                    Image(systemName: "number.circle")
                    Text("str.md.quantityUnits")
                }
            }
            NavigationLink(destination: MDProductGroupsView()) {
                HStack{
                    Image(systemName: "lessthan.circle")
                    Text("str.md.productGroups")
                }
            }
            NavigationLink(destination: MDChoresView()) {
                HStack{
                    Image(systemName: "house")
                    Text("str.md.chores")
                }
            }
            NavigationLink(destination: MDBatteriesView()) {
                HStack{
                    Image(systemName: "battery.25")
                    Text("str.md.batteries")
                }
            }
            NavigationLink(destination: MDTaskCategoriesView()) {
                HStack{
                    Image(systemName: "point.fill.topleft.down.curvedto.point.fill.bottomright.up")
                    Text("str.md.taskCategories")
                }
            }
            NavigationLink(destination: MDUserFieldsView()) {
                HStack{
                    Image(systemName: "bookmark.fill")
                    Text("str.md.userFields")
                }
            }
            NavigationLink(destination: MDUserEntitiesView()) {
                HStack{
                    Image(systemName: "bookmark")
                    Text("str.md.userEntities")
                }
            }
        }
        .animation(.default)
        .navigationTitle("str.md.masterData".localized)
    }
}

struct MasterDataView_Previews: PreviewProvider {
    static var previews: some View {
        MasterDataView()
    }
}
