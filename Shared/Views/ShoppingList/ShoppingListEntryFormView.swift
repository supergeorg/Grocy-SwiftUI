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
    
    @State private var shoppingListID: Int = 1
    @State private var productID: Int?
    @State private var amount: Double = 1.0
    @State private var quantityUnitID: Int?
    @State private var note: String = ""
    
    @State private var showFailToast: Bool = false
    
    var isNewShoppingListEntry: Bool
    var shoppingListEntry: ShoppingListItem?
    var selectedShoppingListID: Int?
    var product: MDProduct?
    
    var isFormValid: Bool {
        return (productID != nil && amount > 0 && quantityUnitID != nil)
    }
    
    private func getQuantityUnit() -> MDQuantityUnit? {
        let quIDP = grocyVM.mdProducts.first(where: {$0.id == productID})?.quIDPurchase
        let qu = grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
        return qu
    }
    private var currentQuantityUnit: MDQuantityUnit? {
        // TODO REMOVE
//        getQuantityUnit()
            //?? MDQuantityUnit(id: 0, name: "Piece", mdQuantityUnitDescription: "", rowCreatedTimestamp: "", namePlural: "Pieces", pluralForms: nil, userfields: nil)
        let quIDP = grocyVM.mdProducts.first(where: {$0.id == productID})?.quIDPurchase
        return grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
    }
    
    private func updateData() {
        grocyVM.requestData(objects: [.shopping_list])
    }
    
    private func finishForm() {
        #if os(iOS)
        self.presentationMode.wrappedValue.dismiss()
        #elseif os(macOS)
        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        #endif
    }
    
    func saveShoppingListEntry() {
        if let productID = productID {
        if isNewShoppingListEntry{
            grocyVM.addShoppingListProduct(content: ShoppingListAddProduct(productID: productID, listID: shoppingListID, productAmount: amount, note: note), completion: { result in
                switch result {
                case let .success(message):
                    print(message)
                    updateData()
                    finishForm()
                case let .failure(error):
                    print("\(error)")
                    showFailToast = true
                }
            })
        } else {
            if let entry = shoppingListEntry {
                grocyVM.putMDObjectWithID(object: .shopping_list, id: entry.id, content: ShoppingListItem(id: entry.id, productID: productID, note: note, amount: amount, shoppingListID: entry.shoppingListID, done: entry.done, quID: entry.quID, rowCreatedTimestamp: entry.rowCreatedTimestamp), completion: { result in
                    switch result {
                    case let .success(message):
                        print(message)
                        updateData()
                        finishForm()
                    case let .failure(error):
                        print("\(error)")
                        showFailToast = true
                    }
                })
            }
        }
        }
    }
    
    private func resetForm() {
        self.shoppingListID = shoppingListEntry?.shoppingListID ?? selectedShoppingListID ?? 1
        self.productID = shoppingListEntry?.productID ?? product?.id
        self.amount = shoppingListEntry?.amount ?? (product != nil ? 1.0 : 0.0)
        self.quantityUnitID = shoppingListEntry?.quID ?? product?.quIDPurchase
        self.note = shoppingListEntry?.note ?? ""
    }
    
    var body: some View {
        #if os(macOS)
        ScrollView{
            content
                .padding()
        }
        .padding()
        #elseif os(iOS)
        NavigationView {
            content
                .navigationTitle(isNewShoppingListEntry ? LocalizedStringKey("str.shL.entryForm.new.title") : LocalizedStringKey("str.shL.entryForm.edit.title"))
                .toolbar{
                    ToolbarItem(placement: .cancellationAction) {
                        Button(LocalizedStringKey("str.cancel")) {
                            finishForm()
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(LocalizedStringKey("str.save")) {
                            saveShoppingListEntry()
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
                }
            
            Section(header: Text(LocalizedStringKey("str.shL.entryForm.amount")).font(.headline)) {
                MyDoubleStepper(amount: $amount, description: "str.shL.entryForm.amount", minAmount: 1, amountName: (amount == 1 ? currentQuantityUnit?.name ?? "" : currentQuantityUnit?.namePlural ?? ""), errorMessage: "str.shL.entryForm.amount.required", systemImage: MySymbols.amount)
                Picker(selection: $quantityUnitID, label: Label(LocalizedStringKey("str.shL.entryForm.quantityUnit"), systemImage: "scalemass"), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id as Int?)
                    }
                }).disabled(true)
            }
            
            Section(header: Label(LocalizedStringKey("str.shL.entryForm.note"), systemImage: "square.and.pencil").labelStyle(TextIconLabelStyle()).font(.headline)) {
                TextEditor(text: $note)
                    .frame(height: 50)
            }
            #if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    finishForm()
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveShoppingListEntry()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid)
            }
            #endif
        }
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: [.shopping_list], ignoreCached: false)
                resetForm()
                firstAppear = false
            }
        })
        .toast(isPresented: $showFailToast, isSuccess: false, content: {Label("str.shL.entryForm.save.failed", systemImage: MySymbols.failure)})
    }
}

struct ShoppingListEntryFormView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListEntryFormView(isNewShoppingListEntry: true)
    }
}
