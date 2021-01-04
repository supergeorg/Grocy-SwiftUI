//
//  StockFilterBarView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct StockFilterBar: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Binding var searchString: String
    @Binding var filteredLocation: String
    @Binding var filteredProductGroup: String
    @Binding var filteredStatus: ProductStatus
    
    var body: some View {
        VStack{
            #if os(iOS)
            if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone) {
                SearchBar(text: $searchString, placeholder: "str.search")
            }
            #endif
        HStack{
            #if os(iOS)
            if !(UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone) {
                SearchBar(text: $searchString, placeholder: "str.search")
            }
            #else
            SearchBar(text: $searchString, placeholder: "str.search")
            #endif
            Spacer()
            HStack{
                Image(systemName: "line.horizontal.3.decrease.circle")
                Picker(selection: $filteredLocation, label: Text(LocalizedStringKey("str.stock.location")), content: {
                    Text(LocalizedStringKey("str.stock.all")).tag("")
                    ForEach(grocyVM.mdLocations, id:\.id) { location in
                        Text(location.name).tag(location.id)
                    }
                }).pickerStyle(MenuPickerStyle())
            }
            Spacer()
            HStack{
                Image(systemName: "line.horizontal.3.decrease.circle")
                Picker(selection: $filteredProductGroup, label: Text(LocalizedStringKey("str.stock.productGroup")), content: {
                    Text(LocalizedStringKey("str.stock.all")).tag("")
                    ForEach(grocyVM.mdProductGroups, id:\.id) { productGroup in
                        Text(productGroup.name).tag(productGroup.id)
                    }
                }).pickerStyle(MenuPickerStyle())
            }
            Spacer()
            HStack{
                Image(systemName: "line.horizontal.3.decrease.circle")
                Picker(selection: $filteredStatus, label: Text(LocalizedStringKey("str.stock.status")), content: {
                    Text(LocalizedStringKey(ProductStatus.all.rawValue))
                        .tag(ProductStatus.all)
                    Text(LocalizedStringKey(ProductStatus.expiringSoon.rawValue))
                        .tag(ProductStatus.expiringSoon)
                        .background(Color.grocyYellowLight)
                    Text(LocalizedStringKey(ProductStatus.overdue.rawValue))
                        .tag(ProductStatus.overdue)
                        .background(Color.grocyGrayLight)
                    Text(LocalizedStringKey(ProductStatus.expired.rawValue))
                        .tag(ProductStatus.expired)
                        .background(Color.grocyRedLight)
                    Text(LocalizedStringKey(ProductStatus.belowMinStock.rawValue))
                        .tag(ProductStatus.belowMinStock)
                        .background(Color.grocyBlueLight)
                }).pickerStyle(MenuPickerStyle())
            }
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
