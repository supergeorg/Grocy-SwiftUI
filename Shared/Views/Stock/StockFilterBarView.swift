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
    @Binding var filteredLocation: String?
    @Binding var filteredProductGroup: String?
    @Binding var filteredStatus: ProductStatus
    
    var body: some View {
        VStack{
            #if os(iOS)
            if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone) {
                SearchBar(text: $searchString, placeholder: "str.search")
                if !searchString.isEmpty {
                    Button("Exit Search") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            #endif
            HStack{
                #if os(iOS)
                if !(UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone) {
                    SearchBar(text: $searchString, placeholder: "str.search")
                }
                Spacer()
                #endif
                Picker(selection: $filteredLocation, label: HStack{
                    Image(systemName: MySymbols.filter)
                    Text(LocalizedStringKey("str.stock.location"))
                }, content: {
                    Text(LocalizedStringKey("str.stock.all")).tag(nil as String?)
                    ForEach(grocyVM.mdLocations, id:\.id) { location in
                        Text(location.name).tag(location.id as String?)
                    }
                })
                .pickerStyle(MenuPickerStyle())
                Spacer()
                Picker(selection: $filteredProductGroup, label: HStack{
                    Image(systemName: MySymbols.filter)
                    Text(LocalizedStringKey("str.stock.productGroup"))
                }, content: {
                    Text(LocalizedStringKey("str.stock.all")).tag(nil as String?)
                    ForEach(grocyVM.mdProductGroups, id:\.id) { productGroup in
                        Text(productGroup.name).tag(productGroup.id as String?)
                    }
                })
                .pickerStyle(MenuPickerStyle())
                Spacer()
                Picker(selection: $filteredStatus, label: HStack{
                    Image(systemName: MySymbols.filter)
                    Text(LocalizedStringKey("str.stock.status"))
                }, content: {
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
                })
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
}

struct StockFilterBar_Previews: PreviewProvider {
    static var previews: some View {
        StockFilterBar(searchString: Binding.constant(""), filteredLocation: Binding.constant(nil), filteredProductGroup: Binding.constant(nil), filteredStatus: Binding.constant(ProductStatus.all))
    }
}
