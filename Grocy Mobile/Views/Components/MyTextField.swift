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
    var subtitle: LocalizedStringKey?
    var prompt: String = ""
    @Binding var isCorrect: Bool
    @FocusState private var isFocused: Bool
    var leadingIcon: String?
    var emptyMessage: LocalizedStringKey?
    var errorMessage: LocalizedStringKey?
    var helpText: LocalizedStringKey?
    
    var body: some View {
        LabeledContent {
            VStack(alignment: .leading, spacing: 0) {
                TextField(prompt, text: $textToEdit)
                    .padding(.vertical, 8)
                    .background(
                        VStack {
                            Spacer()
                            Color(!isCorrect && !textToEdit.isEmpty && errorMessage != nil ? .systemRed : .systemGray)
                                .frame(height: 2)
                        }
                    )
                
                if !isCorrect && !textToEdit.isEmpty, let errorMessage = errorMessage {
                    Text(errorMessage)
                        .lineLimit(nil)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 4)
                }
            }
        } label: {
            HStack(spacing: 4) {
                if let leadingIcon = leadingIcon {
                    Image(systemName: leadingIcon)
                        .foregroundStyle(.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(description)
                            .foregroundStyle(.primary)
                    }
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .lineLimit(nil)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let helpText = helpText {
                    FieldDescription(description: helpText)
                }
            }
        }
    }
}

#Preview {
    Form {
        MyTextField(
            textToEdit: .constant("Text to Edit"),
            description: "Description",
            subtitle: "Optional subtitle",
            isCorrect: .constant(false),
            leadingIcon: "tag",
            errorMessage: "Error message",
            helpText: "This is a help text"
        )
    }
}
