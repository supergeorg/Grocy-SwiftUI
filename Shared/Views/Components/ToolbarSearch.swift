//
//  ToolbarSearch.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct ToolbarSearch: View {
    @Binding var isSearching: Bool
    @Binding var searchString: String
    
    @Namespace var nameSpace
    
    var body: some View {
        if !isSearching {
            Button(action: {
                searchString = ""
                isSearching.toggle()
            }, label: {Image(systemName: "magnifyingglass.circle")})
            .matchedGeometryEffect(id: "search", in: nameSpace)
        } else {
            HStack {
                Button(action: {isSearching.toggle()}, label: {
                    Image(systemName: "xmark.circle")
                })
                .matchedGeometryEffect(id: "search", in: nameSpace)
                TextField("str.md.search \("str.md.quantityUnits".localized)", text: $searchString)
                    .padding()
            }
        }
    }
}

struct ToolbarSearch_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ToolbarSearch(isSearching: Binding.constant(false), searchString: Binding.constant(""))
            ToolbarSearch(isSearching: Binding.constant(true), searchString: Binding.constant("Suche"))
        }
    }
}
