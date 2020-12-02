//
//  ToolbarSearch.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct ToolbarSearch: View {
    @Binding var searchString: String
    
    @Namespace private var animationNameSpace
    
    @State private var isExpanded: Bool = false
    
    func checkIfShouldExpand() {
        if !searchString.isEmpty {
            isExpanded = true
        } else {
//            isExpanded = false
        }
    }
    
    var body: some View {
        Group{
        if !isExpanded {
            Image(systemName: "magnifyingglass")
                .onTapGesture {
                    searchString = ""
                    isExpanded.toggle()
                }
                .matchedGeometryEffect(id: "search", in: animationNameSpace)
        } else {
            HStack {
                Button(action: {isExpanded.toggle()}, label: {
                    Image(systemName: "xmark.circle")
                })
                .matchedGeometryEffect(id: "search", in: animationNameSpace)
                TextField("str.md.search \("str.md.quantityUnits".localized)", text: $searchString)
                    .padding()
            }
        }
        }
        .onChange(of: searchString, perform: { value in
            checkIfShouldExpand()
        })
        .onAppear(perform: {
            checkIfShouldExpand()
        })
    }
}

struct ToolbarSearch_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ToolbarSearch(searchString: Binding.constant(""))
            ToolbarSearch(searchString: Binding.constant("Suche"))
        }
    }
}
