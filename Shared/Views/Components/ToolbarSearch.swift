//
//  ToolbarSearch.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct ToolbarSearch: View {
    @Binding var text: String
    var placeholder: String
    
    @Namespace private var animationNameSpace
    
    @State private var isExpanded: Bool = false
    
    func checkIfShouldExpand() {
        if !text.isEmpty {
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
                    text = ""
                    isExpanded.toggle()
                }
                .matchedGeometryEffect(id: "search", in: animationNameSpace)
        } else {
            HStack {
                Button(action: {isExpanded.toggle()}, label: {
                    Image(systemName: "xmark.circle")
                })
                .matchedGeometryEffect(id: "search", in: animationNameSpace)
                TextField(LocalizedStringKey("str.md.search \("str.md.quantityUnits".localized)"), text: $text)
                    .padding()
            }
        }
        }
        .onChange(of: text, perform: { value in
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
            ToolbarSearch(text: Binding.constant(""), placeholder: "Search")
            ToolbarSearch(text: Binding.constant("Searchstring"), placeholder: "Search")
        }
    }
}
