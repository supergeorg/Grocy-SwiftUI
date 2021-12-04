//
//  ShoppingListAddView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct ShoppingListFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    
    var isNewShoppingListDescription: Bool
    var shoppingListDescription: ShoppingListDescription?
    
    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundShoppingListDescription = grocyVM.shoppingListDescriptions.first(where: {$0.name == name})
        return isNewShoppingListDescription ? !(name.isEmpty || foundShoppingListDescription != nil) : !(name.isEmpty || (foundShoppingListDescription != nil && foundShoppingListDescription!.id != shoppingListDescription!.id))
    }
    
    @State private var showFailToast: Bool = false
    
    private func finishForm() {
        #if os(iOS)
        self.dismiss()
        #elseif os(macOS)
        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        #endif
    }
    
    private func updateData() {
        grocyVM.requestData(objects: [.shopping_lists])
    }
    
    func saveShoppingList() {
        if isNewShoppingListDescription{
            grocyVM.postMDObject(object: .shopping_lists, content: ShoppingListDescription(id: grocyVM.findNextID(.shopping_lists), name: name, shoppingListDescriptionDescription: nil, rowCreatedTimestamp: Date().iso8601withFractionalSeconds), completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog("Shopping list save successful. \(message)", type: .info)
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog("Shopping list save failed. \(error)", type: .error)
                    showFailToast = true
                }
            })
        } else {
            grocyVM.putMDObjectWithID(object: .shopping_lists, id: shoppingListDescription!.id, content: ShoppingListDescription(id: shoppingListDescription!.id, name: name, shoppingListDescriptionDescription: shoppingListDescription!.shoppingListDescriptionDescription, rowCreatedTimestamp: shoppingListDescription!.rowCreatedTimestamp), completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog("Shopping list edit successful. \(message)", type: .info)
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog("Shopping list edit failed. \(error)", type: .error)
                    showFailToast = true
                }
            })
        }
    }
    
    private func resetForm() {
        self.name = shoppingListDescription?.name ?? ""
        isNameCorrect = checkNameCorrect()
    }
    
    var body: some View {
        #if os(macOS)
        content
        #elseif os(iOS)
        NavigationView {
            content
                .navigationTitle(isNewShoppingListDescription ? LocalizedStringKey("str.shL.form.new") : LocalizedStringKey("str.shL.form.edit"))
                .toolbar{
                    ToolbarItem(placement: .cancellationAction) {
                        Button(LocalizedStringKey("str.cancel")) {
                            finishForm()
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(LocalizedStringKey("str.save")) {
                            saveShoppingList()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
        }
        #endif
    }
    
    var content: some View {
        Form {
            #if os(macOS)
            Text(isNewShoppingListDescription ? LocalizedStringKey("str.shL.form.new") : LocalizedStringKey("str.shL.form.edit")).font(.headline)
            #endif
            MyTextField(textToEdit: $name, description: "str.shL.form.name", isCorrect: $isNameCorrect, leadingIcon: "rectangle.and.pencil.and.ellipsis", emptyMessage: "str.shL.form.name.required", errorMessage: "str.shL.form.name.exists")
                .onChange(of: name, perform: {newValue in isNameCorrect = checkNameCorrect()})
            #if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveShoppingList()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
        .onAppear(perform: resetForm)
        .toast(isPresented: $showFailToast, isSuccess: false, text: LocalizedStringKey("str.shL.form.save.failed"))
    }
}

struct ShoppingListFormView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListFormView(isNewShoppingListDescription: true)
    }
}
