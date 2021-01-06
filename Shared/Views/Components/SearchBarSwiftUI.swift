//
//  SearchBar.swift
//  ToDoList
//
//  Created by Simon Ng on 15/4/2020.
//  Copyright © 2020 AppCoda. All rights reserved.
//
import SwiftUI

struct SearchBarSwiftUI: View {
    @Binding var text: String
    
    var placeholder: String
    
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            TextField(LocalizedStringKey(placeholder), text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color.systemGray6)
                .foregroundColor(.black)
                .keyboardShortcut("f", modifiers: .command)
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                    }
                )
                .padding(.horizontal, 10)
                .onTapGesture {
                    self.isEditing = true
                }
            
            if isEditing && !text.isEmpty {
                Image(systemName: "delete.left")
                    .padding(.trailing, 10)
                    .transition(.move(edge: .trailing))
                    .animation(.default)
                    .onTapGesture {
                        self.isEditing = false
                        self.text = ""
                    }
            }
        }
    }
}

struct SearchBarSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        SearchBarSwiftUI(text: .constant(""), placeholder: "Platzhalter")
    }
}
