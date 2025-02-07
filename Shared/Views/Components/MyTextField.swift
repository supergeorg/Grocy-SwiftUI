//
//  MyTextField.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 28.10.20.
//
import SwiftUI

struct MyTextField: View {
    @Binding var textToEdit: String
    var description: LocalizedStringKey
    @Binding var isCorrect: Bool
    @FocusState private var isFocused: Bool
    var leadingIcon: String?
    var emptyMessage: LocalizedStringKey?
    var errorMessage: LocalizedStringKey?
    var helpText: LocalizedStringKey?
    
    var body: some View {
        TextField(text: $textToEdit, prompt: Text(emptyMessage ?? description)) {
            HStack {
                if let leadingIcon = leadingIcon {
                    Label(description, systemImage: leadingIcon)
                } else {
                    Text(description)
                }
                if !isCorrect, !textToEdit.isEmpty, let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                if let helpText = helpText {
                    FieldDescription(description: helpText)
                }
            }
        }
    }
}

#Preview {
    MyTextField(textToEdit: Binding.constant("Text to Edit"), description: "Description", isCorrect: Binding.constant(false), leadingIcon: "tag", errorMessage: "Error")
}
