//
//  ShoppingListEntryFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 02.12.20.
//

import OSLog
import SwiftData
import SwiftUI

struct ShoppingListEntryFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) var dismiss

    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \ShoppingListDescription.id, order: .forward) var shoppingListDescriptions: ShoppingListDescriptions

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingShoppingListEntry: ShoppingListItem?
    @State private var shoppingListEntry: ShoppingListItem

    var selectedShoppingListID: Int?
    var productIDToSelect: Int?
    var isPopup: Bool = false

    var isFormValid: Bool {
        shoppingListEntry.amount > 0 && (shoppingListEntry.productID != -1 || !shoppingListEntry.note.isEmpty) && selectedShoppingListID != -1
    }

    var product: MDProduct? {
        mdProducts.first(where: { $0.id == shoppingListEntry.productID })
    }

    init(existingShoppingListEntry: ShoppingListItem? = nil, selectedShoppingListID: Int? = nil, productIDToSelect: Int? = nil, isPopup: Bool = false) {
        self.existingShoppingListEntry = existingShoppingListEntry
        self.selectedShoppingListID = selectedShoppingListID
        self.productIDToSelect = productIDToSelect
        self.isPopup = isPopup
        self.shoppingListEntry = existingShoppingListEntry ?? ShoppingListItem(productID: productIDToSelect ?? -1, shoppingListID: selectedShoppingListID ?? -1)
    }

    private func getQuantityUnit() -> MDQuantityUnit? {
        let quIDP = mdProducts.first(where: { $0.id == shoppingListEntry.productID })?.quIDPurchase
        let qu = mdQuantityUnits.first(where: { $0.id == quIDP })
        return qu
    }

    private var currentQuantityUnit: MDQuantityUnit? {
        let quIDP = mdProducts.first(where: { $0.id == shoppingListEntry.productID })?.quIDPurchase
        return mdQuantityUnits.first(where: { $0.id == quIDP })
    }

    private func updateData() async {
        await grocyVM.requestData(objects: [.shopping_list])
    }

    private func finishForm() {
        dismiss()
    }

    private func saveShoppingListEntry() async {
        if shoppingListEntry.id == -1 {
            do {
                shoppingListEntry.id = try grocyVM.findNextID(.shopping_list)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        do {
            try shoppingListEntry.modelContext?.save()
            if existingShoppingListEntry == nil {
                _ = try await grocyVM.postMDObject(object: .shopping_list, content: shoppingListEntry)
            } else {
                try await grocyVM.putMDObjectWithID(object: .shopping_list, id: shoppingListEntry.id, content: shoppingListEntry)
            }
            GrocyLogger.info("Shopping list entry saved successfully.")
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Shopping entry failed. \(error)")
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
            isSuccessful = false
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            Picker(
                selection: $shoppingListEntry.shoppingListID,
                label: Label("Shopping list", systemImage: MySymbols.shoppingList),
                content: {
                    Text("").tag(-1)
                    ForEach(shoppingListDescriptions, id: \.id) { shLDescription in
                        Text(shLDescription.name).tag(shLDescription.id)
                    }
                }
            )
            .foregroundStyle(.primary)

            ProductField(productID: $shoppingListEntry.productID, description: "Product")
                .onChange(of: shoppingListEntry.productID) {
                    if let selectedProduct = mdProducts.first(where: { $0.id == shoppingListEntry.productID }) {
                        shoppingListEntry.quID = selectedProduct.quIDPurchase
                    }
                }

            AmountSelectionView(productID: $shoppingListEntry.productID, amount: $shoppingListEntry.amount, quantityUnitID: $shoppingListEntry.quID)

            Section(
                header: Label("Note", systemImage: "square.and.pencil")
                    .labelStyle(.titleAndIcon)
                    .font(.headline)
            ) {
                TextEditor(text: $shoppingListEntry.note)
                    .frame(height: 50)
            }
        }
        .navigationTitle(existingShoppingListEntry == nil ? "Create shopping list item" : "Edit shopping list item")
        .task {
            await updateData()
            if shoppingListEntry.shoppingListID == -1 {
                shoppingListEntry.shoppingListID = shoppingListDescriptions.first?.id ?? -1
            }
            if shoppingListEntry.quID == -1, let selectedProduct = mdProducts.first(where: { $0.id == shoppingListEntry.productID }) {
                shoppingListEntry.quID = selectedProduct.quIDPurchase
            }
        }
        .toolbar {
            if isPopup {
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button(
                            role: .cancel,
                            action: {
                                finishForm()
                            }
                        )
                        .keyboardShortcut(.cancelAction)
                    }
                )
            }
            ToolbarItem(
                placement: .confirmationAction,
                content: {
                    Button(
                        role: .confirm,
                        action: {
                            Task {
                                await saveShoppingListEntry()
                            }
                        },
                        label: {
                            if !isProcessing {
                                Label("Save", systemImage: MySymbols.save)
                                    .labelStyle(.titleAndIcon)
                            } else {
                                ProgressView().progressViewStyle(.circular)
                            }
                        }
                    )
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isFormValid || isProcessing)
                }
            )
        }
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                finishForm()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        ShoppingListEntryFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        ShoppingListEntryFormView(existingShoppingListEntry: ShoppingListItem(id: 1, amount: 1.0, shoppingListID: 1, done: false))
    }
}
