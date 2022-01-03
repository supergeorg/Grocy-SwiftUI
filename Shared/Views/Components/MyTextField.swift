//
//  MyTextField.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 28.10.20.
//
import SwiftUI

struct MyTextField: View {
    @Binding var textToEdit: String
    var description: String
    @Binding var isCorrect: Bool
    @FocusState private var isFocused: Bool
    var leadingIcon: String?
    var emptyMessage: String?
    var errorMessage: String?
    var helpText: String?
    
    var showSmallDescription: Bool {
        ((isFocused && !textToEdit.isEmpty) || !textToEdit.isEmpty)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if let helpText = helpText {
                HStack {
                    Spacer()
                    FieldDescription(description: helpText)
                }
            }
#if os(iOS)
            Text(LocalizedStringKey(description))
                .font(showSmallDescription ? .caption : .body)
                .foregroundColor(isCorrect ? Color.gray : Color.red)
                .padding(.top, showSmallDescription ? 0 : 16)
                .padding(.leading, (leadingIcon == nil || showSmallDescription) ? 0 : 30)
                .opacity(showSmallDescription ? 1 : 0)
                .animation(.default, value: showSmallDescription)
                .zIndex(0)
#endif
            HStack {
                if leadingIcon != nil {
                    Image(systemName: leadingIcon!)
                        .padding(.top, 15)
                        .frame(width: 20, height: 20)
                }
                TextField(LocalizedStringKey(description), text: self.$textToEdit)
                    .disableAutocorrection(true)
                    .focused($isFocused)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.top, 15)
                    .zIndex(1)
            }
            VStack(alignment: .leading) {
                if isFocused {
                    Divider()
                        .background(isCorrect ? Color.primary : Color.red)
                        .padding(.top, 40)
                        .zIndex(2)
                    if !isCorrect {
                        if textToEdit.isEmpty {
                            if let emptyMessage = emptyMessage {
                                Text(LocalizedStringKey(emptyMessage))
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .animation(.default, value: textToEdit.isEmpty)
                            }
                        } else {
                            if let errorMessage = errorMessage {
                                Text(LocalizedStringKey(errorMessage))
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .animation(.default, value: (!isCorrect && !textToEdit.isEmpty))
                            }
                        }
                    }
                }
            }
        }
    }
}

struct MyTextField_Previews: PreviewProvider {
    static var previews: some View {
        MyTextField(textToEdit: Binding.constant("Text to Edit"), description: "Description", isCorrect: Binding.constant(false), leadingIcon: "tag", errorMessage: "Error")
            .padding()
    }
}
