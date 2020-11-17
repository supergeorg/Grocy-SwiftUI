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
    var errorMessage: String?
    var description2: String
    
    init(textToEdit: Binding<String>, description: String, isCorrect: Binding<Bool>, leadingIcon: String? = nil, isEditing: Bool? = true, errorMessage: String? = nil) {
        self._textToEdit = textToEdit
        self.description = description
        self._isCorrect = isCorrect
        self.leadingIcon = leadingIcon
        self.isEditing = isEditing ?? true
        self.errorMessage = errorMessage
//        self._editMode = editMode ?? Binding.constant(EditMode.active)
        #if os(iOS)
        self.description2 = ""
        #else
        self.description2 = description
        #endif
        
        self._isEnteringText = State(initialValue: !textToEdit.wrappedValue.isEmpty)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                Text(LocalizedStringKey(description))
                    .font(isEnteringText ? .caption : .body)
                    .foregroundColor(isCorrect ? Color.gray : Color.red)
                    .padding(.top, isEnteringText ? 0 : 16)
                    .padding(.leading, (leadingIcon == nil || isEnteringText) ? 0 : 30)
                    .zIndex(0)
            }
            HStack {
                if leadingIcon != nil {
                    Image(systemName: leadingIcon!)
                        .padding(.top, 15)
                        .frame(width: 20, height: 20)
                }
                if isEditing {
                    TextField(description2.localized, text: self.$textToEdit)
//                        .autocapitalization(.none)
                        .disableAutocorrection(true)
//                        .textContentType(.URL)
                        .font(.body)
//                        .shadow(color: .red, radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/)
//                                            .foregroundColor(.white)
//                                            .padding(.bottom, 15)
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
                    if errorMessage != nil && !isCorrect {
                        Text(errorMessage!.localized)
                            .foregroundColor(.red)
                            .font(.caption)
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
