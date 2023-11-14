//
//  ShoppingListEntryFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 02.12.20.
//

import SwiftUI
import SwiftData

struct ShoppingListEntryFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \ShoppingListDescription.id, order: .forward) var shoppingListDescriptions: ShoppingListDescriptions
    
    @Environment(\.dismiss) var dismiss
    
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
    var productIDToSelect: Int?
    var isPopup: Bool = false
    
    var isFormValid: Bool {
        amount > 0
    }
    
    var product: MDProduct? {
        mdProducts.first(where: { $0.id == productID })
    }
    
    private func getQuantityUnit() -> MDQuantityUnit? {
        let quIDP = mdProducts.first(where: { $0.id == productID })?.quIDPurchase
        let qu = mdQuantityUnits.first(where: { $0.id == quIDP })
        return qu
    }
    
    private var currentQuantityUnit: MDQuantityUnit? {
        let quIDP = mdProducts.first(where: { $0.id == productID })?.quIDPurchase
        return mdQuantityUnits.first(where: { $0.id == quIDP })
    }
    
    private func updateData() async {
        await grocyVM.requestData(objects: [.shopping_list])
    }
    
    private func finishForm() {
#if os(iOS)
        dismiss()
#elseif os(macOS)
        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
#endif
    }
    
    func saveShoppingListEntry() async {
        if isNewShoppingListEntry {
            let newShoppingListEntry = ShoppingListItemAdd(
                amount: amount,
                note: note,
                productID: productID,
                quID: quantityUnitID,
                shoppingListID: shoppingListID
            )
            do {
                try await grocyVM.addShoppingListItem(content: newShoppingListEntry)
                await grocyVM.postLog("Shopping list entry saved successfully.", type: .info)
                await updateData()
                finishForm()
            } catch {
                await grocyVM.postLog("Shopping list entry save failed. \(error)", type: .error)
                showFailToast = true
            }
        } else {
            if let entry = shoppingListEntry {
                let editedShoppingListEntry = ShoppingListItem(
                    id: entry.id,
                    productID: productID,
                    note: note,
                    amount: amount,
                    shoppingListID: shoppingListID,
                    done: entry.done,
                    quID: quantityUnitID,
                    rowCreatedTimestamp: entry.rowCreatedTimestamp
                )
                do {
                    try await grocyVM.putMDObjectWithID(
                        object: .shopping_list,
                        id: entry.id,
                        content: editedShoppingListEntry
                    )
                    await grocyVM.postLog("Shopping entry edited successfully.", type: .info)
                    await updateData()
                    finishForm()
                } catch {
                    await grocyVM.postLog("Shopping entry edit failed. \(error)", type: .error)
                    showFailToast = true
                }
            }
        }
    }
    
    private func resetForm() {
        shoppingListID = shoppingListEntry?.shoppingListID ?? selectedShoppingListID ?? 1
        productID = shoppingListEntry?.productID ?? product?.id
        amount = shoppingListEntry?.amount ?? (product != nil ? 1.0 : 0.0)
        quantityUnitID = shoppingListEntry?.quID ?? product?.quIDPurchase
        note = shoppingListEntry?.note ?? ""
    }
    
    var body: some View {
        content
            .navigationTitle(isNewShoppingListEntry ? "Create shopping list item" : "Edit shopping list item")
#if os(iOS)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewShoppingListEntry {
                        Button("Cancel", role: .cancel, action: finishForm)
                            .keyboardShortcut(.cancelAction)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveShoppingListEntry()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isFormValid)
                }
            }
#endif
    }
    
    var content: some View {
        Form {
#if os(macOS)
            Text(isNewShoppingListEntry ? "Create shopping list item" : "Edit shopping list item").font(.headline)
#endif
            Picker(selection: $shoppingListID, label: Text("Shopping list"), content: {
                ForEach(shoppingListDescriptions, id: \.id) { shLDescription in
                    Text(shLDescription.name).tag(shLDescription.id)
                }
            })
            
            ProductField(productID: $productID, description: "Product")
                .onChange(of: productID) {
                    if let selectedProduct = mdProducts.first(where: { $0.id == productID }) {
                        quantityUnitID = selectedProduct.quIDPurchase
                    }
                }
            
            AmountSelectionView(productID: $productID, amount: $amount, quantityUnitID: $quantityUnitID)
            
            Section(header: Label("Note", systemImage: "square.and.pencil")
                .labelStyle(.titleAndIcon)
                .font(.headline)) {
                    TextEditor(text: $note)
                        .frame(height: 50)
                }
#if os(macOS)
            HStack {
                Button("Cancel") {
                    finishForm()
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    Task {
                        await saveShoppingListEntry()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid)
            }
#endif
        }
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
    }
}

struct ShoppingListEntryFormView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListEntryFormView(isNewShoppingListEntry: true)
    }
}
