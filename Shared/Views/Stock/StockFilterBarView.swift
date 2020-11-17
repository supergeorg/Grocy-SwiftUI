//
//  StockFilterBarView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct StockFilterBar: View {
    @StateObject private var grocyVM = GrocyViewModel()
    
    @Binding var searchString: String
    @Binding var filteredLocation: String
    @Binding var filteredProductGroup: String
    @Binding var filteredStatus: ProductStatus
    
    var body: some View {
        HStack{
            HStack{
                Image(systemName: "magnifyingglass")
                TextField("Search", text: $searchString)
            }
            Spacer()
            HStack{
                Image(systemName: "line.horizontal.3.decrease.circle")
                Picker(selection: $filteredLocation, label: Text("Standort"), content: {
                    Text("str.stock.all").tag("")
                    ForEach(grocyVM.mdLocations, id:\.id) { location in
                        Text(location.name).tag(location.id)
                    }
                }).pickerStyle(MenuPickerStyle())
            }
            Spacer()
            HStack{
                Image(systemName: "line.horizontal.3.decrease.circle")
                Picker(selection: $filteredProductGroup, label: Text("Produktgruppe"), content: {
                    Text("str.stock.all").tag("")
                    ForEach(grocyVM.mdProductGroups, id:\.id) { productGroup in
                        Text(productGroup.name).tag(productGroup.id)
                    }
                }).pickerStyle(MenuPickerStyle())
            }
            Spacer()
            HStack{
                Image(systemName: "line.horizontal.3.decrease.circle")
                Picker(selection: $filteredStatus, label: Text("Status"), content: {
                    Text(ProductStatus.all.rawValue.localized).tag(ProductStatus.all)
                    Text(ProductStatus.expiringSoon.rawValue.localized).tag(ProductStatus.expiringSoon)
                    Text(ProductStatus.expired.rawValue.localized).tag(ProductStatus.expired)
                    Text(ProductStatus.belowMinStock.rawValue.localized).tag(ProductStatus.belowMinStock)
                }).pickerStyle(MenuPickerStyle())
            }
        }
    }
}

//struct StockFilterBar_Previews: PreviewProvider {
//    static var previews: some View {
//        StockFilterBar()
//    }
//}

//HStack{
//    Picker(selection: $filteredLocation, label: FilterSettingView(name: "str.stock.location", selection: filteredLocation.isEmpty ? "str.stock.all".localized : grocyVM.mdLocations.first(where: {$0.id == filteredLocation})?.name ?? "Fehler"),content: {
//        Text("str.stock.all").tag("")
//        ForEach(grocyVM.mdLocations, id:\.id) { location in
//            Text(location.name).tag(location.id)
//        }
//    }).pickerStyle(MenuPickerStyle())
//    Spacer()
//    Picker(selection: $filteredProductGroup, label: FilterSettingView(name: "str.stock.productGroup", selection: filteredProductGroup.isEmpty ? "str.stock.all".localized : grocyVM.mdProductGroups.first(where: {$0.id == filteredProductGroup})?.name ?? "Fehler"), content: {
//        Text("str.stock.all").tag("")
//        ForEach(grocyVM.mdProductGroups, id:\.id) { productGroup in
//            Text(productGroup.name).tag(productGroup.id)
//        }
//    }).pickerStyle(MenuPickerStyle())
//    Spacer()
//    Picker(selection: $filteredStatus, label: FilterSettingView(name: "str.stock.status", selection: filteredStatus.rawValue), content: {
//        Text(ProductStatus.all.rawValue.localized).tag(ProductStatus.all)
//        Text(ProductStatus.expiringSoon.rawValue.localized).tag(ProductStatus.expiringSoon)
//        Text(ProductStatus.expired.rawValue.localized).tag(ProductStatus.expired)
//        Text(ProductStatus.belowMinStock.rawValue.localized).tag(ProductStatus.belowMinStock)
//    }).pickerStyle(MenuPickerStyle())
