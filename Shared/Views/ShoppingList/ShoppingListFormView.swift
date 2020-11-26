//
//  ShoppingListAddView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct ShoppingListFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    
    var isNewShoppingListDescription: Bool
    var shoppingListDescription: ShoppingListDescription?
    
    @State var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundShoppingListDescription = grocyVM.shoppingListDescriptions.first(where: {$0.name == name})
        return isNewShoppingListDescription ? !(name.isEmpty || foundShoppingListDescription != nil) : !(name.isEmpty || (foundShoppingListDescription != nil && foundShoppingListDescription!.id != shoppingListDescription!.id))
    }
    
    func saveShoppingList() {
        if isNewShoppingListDescription{
            grocyVM.postMDObject(object: .shopping_lists, content: ShoppingListDescriptionPOST(id: grocyVM.findNextID(.shopping_lists), name: name, shoppingListDescriptionDescription: nil, rowCreatedTimestamp: Date().iso8601withFractionalSeconds, userfields: nil))
        } else {
            grocyVM.putMDObjectWithID(object: .shopping_lists, id: shoppingListDescription!.id, content: ShoppingListDescriptionPOST(id: Int(shoppingListDescription!.id)!, name: name, shoppingListDescriptionDescription: shoppingListDescription!.shoppingListDescriptionDescription, rowCreatedTimestamp: shoppingListDescription!.rowCreatedTimestamp, userfields: nil))
        }
        grocyVM.getShoppingListDescriptions()
    }
    
    private func resetForm() {
        if isNewShoppingListDescription {
            self.name = ""
        } else {
            self.name = shoppingListDescription!.name
        }
        isNameCorrect = checkNameCorrect()
    }
    
    var body: some View {
        #if os(macOS)
        content
        #elseif os(iOS)
        NavigationView {
            content
                .navigationTitle(isNewShoppingListDescription ? "str.shL.new.title" : "str.shL.edit.title")
        }
        #endif
    }

    var content: some View {
        Form {
            #if os(macOS)
            Text(isNewShoppingListDescription ? "str.shL.new.title" : "str.shL.edit.title").font(.headline)
            #endif
            MyTextField(textToEdit: $name, description: "str.shL.new.name", isCorrect: $isNameCorrect, leadingIcon: "rectangle.and.pencil.and.ellipsis", isEditing: true, errorMessage: "str.shL.new.name.required")
            #if os(macOS)
            HStack{
                Button("str.cancel") {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("str.save") {
                    saveShoppingList()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
        .animation(.default)
        .onAppear(perform: resetForm)
    }
}

struct ShoppingListFormView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListFormView(isNewShoppingListDescription: true)
    }
}
