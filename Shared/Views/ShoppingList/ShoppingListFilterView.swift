//
//  ShoppingListFilterView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 27.11.20.
//

import SwiftUI

struct ShoppingListFilterView: View {
    @Binding var searchString: String
    @Binding var filteredStatus: ShoppingListStatus
    
    var body: some View {
        HStack{
            SearchBar(text: $searchString, placeholder: "str.search")
            Picker(selection: $filteredStatus, label: Label(LocalizedStringKey("str.shL.filter.status"), systemImage: MySymbols.filter), content: {
                Text(LocalizedStringKey(ShoppingListStatus.all.rawValue)).tag(ShoppingListStatus.all)
                Text(LocalizedStringKey(ShoppingListStatus.belowMinStock.rawValue)).tag(ShoppingListStatus.belowMinStock)
                Text(LocalizedStringKey(ShoppingListStatus.done.rawValue)).tag(ShoppingListStatus.done)
                Text(LocalizedStringKey(ShoppingListStatus.undone.rawValue)).tag(ShoppingListStatus.undone)

            }).pickerStyle(MenuPickerStyle())
        }
        .padding(.trailing, 5)
    }
}

struct ShoppingListFilterView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListFilterView(searchString: Binding.constant("search"), filteredStatus: Binding.constant(ShoppingListStatus.all))
    }
}
