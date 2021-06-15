//
//  MyTextField.swift
//  grocy-ios
//
//  Created by Georg Meissner on 28.10.20.
//

import SwiftUI

struct MyTextField: View {
    @Binding var textToEdit: String
    var description: String
    @Binding var isCorrect: Bool
    @State var isEnteringText: Bool
    var leadingIcon: String?
    var isEditing: Bool
    var emptyMessage: String?
    var errorMessage: String?
    var description2: String
    var helpText: String?
    
    init(textToEdit: Binding<String>, description: String, isCorrect: Binding<Bool>, leadingIcon: String? = nil, isEditing: Bool? = true, emptyMessage: String? = nil, errorMessage: String? = nil, helpText: String? = nil) {
        self._textToEdit = textToEdit
        self.description = description
        self._isCorrect = isCorrect
        self.leadingIcon = leadingIcon
        self.isEditing = isEditing ?? true
        self.errorMessage = errorMessage
        self.helpText = helpText
        self.emptyMessage = emptyMessage
        #if os(iOS)
        self.description2 = ""
        #else
        self.description2 = description
        #endif
        
        self._isEnteringText = State(initialValue: !textToEdit.wrappedValue.isEmpty)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack{
                Spacer()
                if let helpTextU = helpText {
                    FieldDescription(description: helpTextU)
                }
            }
            VStack {
                #if os(macOS)
                if isEnteringText {
                    Text(LocalizedStringKey(description))
                        .font(.caption)
                        .foregroundColor(isCorrect ? Color.gray : Color.red)
                        .padding(.top, 0)
                        .padding(.leading, 0)
                        .zIndex(0)
                }
                #else
                Text(LocalizedStringKey(description))
                    .font(isEnteringText ? .caption : .body)
                    .foregroundColor(isCorrect ? Color.gray : Color.red)
                    .padding(.top, isEnteringText ? 0 : 16)
                    .padding(.leading, (leadingIcon == nil || isEnteringText) ? 0 : 30)
                    .zIndex(0)
                #endif
            }
            HStack {
                if leadingIcon != nil {
                    Image(systemName: leadingIcon!)
                        .padding(.top, 15)
                        .frame(width: 20, height: 20)
                }
                if isEditing {
                    TextField(LocalizedStringKey(description2), text: self.$textToEdit)
                        .disableAutocorrection(true)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 15)
                        .onTapGesture {
                            self.isEnteringText = true
                        }
                        .onChange(of: textToEdit, perform: { value in
                            if textToEdit.isEmpty {
                                self.isEnteringText = false
                            } else {
                                self.isEnteringText = true
                            }
                        })
                        .zIndex(1)
                } else {
                    Text(textToEdit)
                        .font(.body)
                        .padding(.top, 15)
                        .zIndex(1)
                }
            }
            VStack(alignment: .leading) {
                if isEditing {
                    Divider()
                        .background(isCorrect ? Color.primary : Color.red)
                        .padding(.top, 40)
                        .zIndex(2)
                    if !isCorrect {
                        if textToEdit.isEmpty {
                            if let emptyMessageU = emptyMessage {
                                Text(LocalizedStringKey(emptyMessageU))
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        } else {
                            if let errorMessageU = errorMessage {
                                Text(LocalizedStringKey(errorMessageU))
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .animation(.default)
    }
}

struct MyTextField_Previews: PreviewProvider {
    static var previews: some View {
        MyTextField(textToEdit: Binding.constant("Affe"), description: "Beschreibung", isCorrect: Binding.constant(false), leadingIcon: "tag", isEditing: true, errorMessage: "Fehler")
            .padding()
    }
}
