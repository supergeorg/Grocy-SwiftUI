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
        LabeledContent(content: {
            TextEditor(text: $textToEdit)
        }, label: {
            HStack {
                if let leadingIcon = leadingIcon {
                    Label(description, systemImage: leadingIcon)
                        .foregroundStyle(.primary)
                } else {
                    Text(description)
                }
            }
        })
        
    }
}

#Preview {
    MyTextEditor(textToEdit: Binding.constant("TEST"), description: "DESCRIPTION")
}
