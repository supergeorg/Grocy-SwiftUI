//
//  ShoppingListEntryFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 02.12.20.
//

import SwiftUI

//"str.shL.newEntry.new.title" = "Einkaufszettel Eintrag erstellen";
//"str.shL.newEntry.edit.title" = "Einkaufszettel Eintrag bearbeiten";
//"str.shL.newEntry.shoppingList" = "Einkaufszettel";
//"str.shL.newEntry.product" = "Produkt";
//"str.shL.newEntry.amount" = "Menge";
//"str.shL.newEntry.quantityUnit" = "Mengeneinheit";
//"str.shL.newEntry.note" = "Notiz";

struct ShoppingListEntryFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
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
    
    private func insertToEditForm() {
        if !isNewShoppingListEntry {
            self.shoppingListID = shoppingListEntry!.shoppingListID
            self.productID = shoppingListEntry!.productID ?? ""
            self.amount = Int(shoppingListEntry!.amount) ?? 0
            self.quantityUnitID = shoppingListEntry!.quID ?? ""
            self.note = shoppingListEntry!.note ?? ""
        } else {
            self.shoppingListID = selectedShoppingListID ?? "1"
            self.productID = product?.id ?? ""
            self.amount = product != nil ? 1 : 0
            self.quantityUnitID = product?.quIDPurchase ?? ""
        }
    }
    
    var body: some View {
        #if os(macOS)
        content
        #elseif os(iOS)
        NavigationView {
            content
                .navigationTitle(isNewShoppingListEntry ? "str.shL.newEntry.new.title" : "str.shL.newEntry.edit.title")
                .toolbar{
                    ToolbarItem(placement: .cancellationAction) {
                        Button("str.cancel") {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("str.save") {
                            saveShoppingListEntry()
                            self.presentationMode.wrappedValue.dismiss()
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(!isFormValid)
                    }
                }
        }
        #endif
    }
    
    var content: some View {
        Form {
            #if os(macOS)
            Text(isNewShoppingListEntry ? "str.shL.newEntry.new.title" : "str.shL.newEntry.edit.title").font(.headline)
            #endif
            Picker(selection: $shoppingListID, label: Text("str.shL.newEntry.shoppingList"), content: {
                ForEach(grocyVM.shoppingListDescriptions, id:\.id) { shLDescription in
                    Text(shLDescription.name).tag(shLDescription.id)
                }
            })
            Picker(selection: $productID, label: Text("str.shL.newEntry.product"), content: {
                ForEach(grocyVM.mdProducts, id:\.id) { mdProduct in
                    Text(mdProduct.name).tag(mdProduct.id)
                }
            })
            .onChange(of: productID) { newProduct in
                if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                    quantityUnitID = selectedProduct.quIDPurchase
                }
            }
            Section(header: Text("str.shL.newEntry.amount".localized).font(.headline)) {
                MyIntStepper(amount: $amount, description: "str.shL.newEntry.amount", minAmount: 1, amountName: (amount == 1 ? currentQuantityUnit.name : currentQuantityUnit.namePlural), errorMessage: "str.shL.newEntry.amount.required", systemImage: "number.circle")
                Picker(selection: $quantityUnitID, label: Label("str.shL.newEntry.quantityUnit".localized, systemImage: "scalemass"), content: {
                    Text("").tag("")
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id)
                    }
                }).disabled(true)
            }
            Section(header: HStack {
                Text("str.shL.newEntry.note")
                Image(systemName: "square.and.pencil")
            }) {
                TextEditor(text: $note)
                    .frame(height: 50)
            }
            #if os(macOS)
            HStack{
                Button("str.cancel") {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("str.save") {
                    saveShoppingListEntry()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid)
            }
            #endif
        }
        .animation(.default)
        .onAppear(perform: insertToEditForm)
    }
}

struct ShoppingListEntryFormView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListEntryFormView(isNewShoppingListEntry: true)
    }
}
