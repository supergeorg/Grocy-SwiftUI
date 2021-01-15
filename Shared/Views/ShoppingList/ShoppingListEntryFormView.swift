//
//  ShoppingListEntryFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 02.12.20.
//

import SwiftUI

struct ShoppingListEntryFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstAppear: Bool = true
    
    @State private var shoppingListID: String = "1"
    @State private var productID: String = ""
    @State private var amount: Int = 0
    @State private var quantityUnitID: String = ""
    @State private var note: String = ""
    
    var isNewShoppingListEntry: Bool
    var shoppingListEntry: ShoppingListItem?
    var selectedShoppingListID: String?
    var product: MDProduct?
    
    var isFormValid: Bool {
        return (!shoppingListID.isEmpty && !productID.isEmpty && amount > 0 && !quantityUnitID.isEmpty)
    }
    
    private func getQuantityUnit() -> MDQuantityUnit? {
        let quIDP = grocyVM.mdProducts.first(where: {$0.id == productID})?.quIDPurchase
        let qu = grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
        return qu
    }
    private var currentQuantityUnit: MDQuantityUnit {
        getQuantityUnit() ?? MDQuantityUnit(id: "0", name: "Stück", mdQuantityUnitDescription: "", rowCreatedTimestamp: "", namePlural: "Stücke", pluralForms: nil, userfields: nil)
    }
    
    func saveShoppingListEntry() {
        let intProductID = Int(productID)!
        let intShoppingListID = Int(shoppingListID)!
        if isNewShoppingListEntry{
            grocyVM.addShoppingListProduct(content: ShoppingListAddProduct(productID: intProductID, listID: intShoppingListID, productAmount: amount, note: note))
        } else {
            if let entry = shoppingListEntry {
                grocyVM.putMDObjectWithID(object: .shopping_list, id: entry.id, content: ShoppingListItem(id: entry.id, productID: productID, note: note, amount: String(amount), rowCreatedTimestamp: entry.rowCreatedTimestamp, shoppingListID: shoppingListID, done: entry.done, quID: quantityUnitID, userfields: entry.userfields))
            }
        }
        grocyVM.getShoppingList()
    }
    
    private func resetForm() {
            self.shoppingListID = shoppingListEntry?.shoppingListID ?? selectedShoppingListID ?? "1"
            self.productID = shoppingListEntry?.productID ?? product?.id ?? ""
            self.amount = Int(shoppingListEntry?.amount ?? "") ?? (product != nil ? 1 : 0)
            self.quantityUnitID = shoppingListEntry?.quID ?? product?.quIDPurchase ?? ""
            self.note = shoppingListEntry?.note ?? ""
    }
    
    private func updateData() {
        
    }
    
    var body: some View {
        #if os(macOS)
        content
        #elseif os(iOS)
        NavigationView {
            content
                .navigationTitle(isNewShoppingListEntry ? LocalizedStringKey("str.shL.entryForm.new.title") : LocalizedStringKey("str.shL.entryForm.edit.title"))
                .toolbar{
                    ToolbarItem(placement: .cancellationAction) {
                        Button(LocalizedStringKey("str.cancel")) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(LocalizedStringKey("str.save")) {
                            saveShoppingListEntry()
                            self.presentationMode.wrappedValue.dismiss()
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(!isFormValid)
                    }
                }
                .animation(.default)
        }
        #endif
    }
    
    var content: some View {
        Form {
            #if os(macOS)
            Text(isNewShoppingListEntry ? LocalizedStringKey("str.shL.entryForm.new.title") : LocalizedStringKey("str.shL.entryForm.edit.title")).font(.headline)
            #endif
            Picker(selection: $shoppingListID, label: Text(LocalizedStringKey("str.shL.entryForm.shoppingList")), content: {
                ForEach(grocyVM.shoppingListDescriptions, id:\.id) { shLDescription in
                    Text(shLDescription.name).tag(shLDescription.id)
                }
            })
            
            ProductField(productID: $productID, description: "str.shL.entryForm.product")
            .onChange(of: productID) { newProduct in
                if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                    quantityUnitID = selectedProduct.quIDPurchase
                }
                print(productID)
            }
            
            Section(header: Text(LocalizedStringKey("str.shL.entryForm.amount")).font(.headline)) {
                MyIntStepper(amount: $amount, description: "str.shL.entryForm.amount", minAmount: 1, amountName: (amount == 1 ? currentQuantityUnit.name : currentQuantityUnit.namePlural), errorMessage: "str.shL.entryForm.amount.required", systemImage: "number.circle")
                Picker(selection: $quantityUnitID, label: Label(LocalizedStringKey("str.shL.entryForm.quantityUnit"), systemImage: "scalemass"), content: {
                    Text("").tag("")
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id)
                    }
                }).disabled(true)
            }
            
            Section(header: HStack {
                Text(LocalizedStringKey("str.shL.entryForm.note"))
                Image(systemName: "square.and.pencil")
            }.font(.headline)) {
                TextEditor(text: $note)
                    .frame(height: 50)
            }
            #if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveShoppingListEntry()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid)
            }
            #endif
        }
        .onAppear(perform: {
            if firstAppear {
                updateData()
                resetForm()
                firstAppear = false
            }
        })
    }
}

struct ShoppingListEntryFormView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListEntryFormView(isNewShoppingListEntry: true)
    }
}