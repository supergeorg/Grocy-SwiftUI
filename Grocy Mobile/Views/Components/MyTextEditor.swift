//
//  MyTextEditor.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.09.23.
//

import SwiftUI

struct MyTextEditor: View {
    @Binding var textToEdit: String
    var description: LocalizedStringKey
    var leadingIcon: String?
    
    var body: some View {
        TextEditor(text: $textToEdit)
    }
}

#Preview {
    MyTextEditor(textToEdit: Binding.constant("TEST"), description: "DESCRIPTION")
}
