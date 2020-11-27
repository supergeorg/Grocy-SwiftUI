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
            SearchBar(text: $searchString, placeholder: "str.search".localized)
            Picker(selection: $filteredStatus, label: Label("str.shL.filter.status".localized, systemImage: "line.horizontal.3.decrease.circle"), content: {
                Text(ShoppingListStatus.all.rawValue.localized).tag(ShoppingListStatus.all)
                Text(ShoppingListStatus.belowMinStock.rawValue.localized).tag(ShoppingListStatus.belowMinStock)
                Text(ShoppingListStatus.undone.rawValue.localized).tag(ShoppingListStatus.undone)

            })
            Button(action: {
                searchString = ""
                filteredStatus = .all
            }, label: {
                Text("str.shL.filter.reset")
            })
        }
        .padding(.trailing, 5)
    }
}

struct ShoppingListFilterView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListFilterView(searchString: Binding.constant("search"), filteredStatus: Binding.constant(ShoppingListStatus.all))
    }
}
