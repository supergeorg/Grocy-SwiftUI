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
    @Environment(\.grocyFeatures) private var features

    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(sort: \ShoppingListDescription.id, order: .forward) var shoppingListDescriptions: ShoppingListDescriptions

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingShoppingListEntry: ShoppingListItem?
    @State private var shoppingListEntry: ShoppingListItem
    /// The amount in the chosen unit. Grocy stores a product's amount in its stock unit, so it's converted when loading and saving (#114).
    @State private var displayAmount: Double
    @State private var didLoadDisplayAmount: Bool = false

    var selectedShoppingListID: Int?
    var productIDToSelect: Int?
    var isPopup: Bool = false

    /// Grocy 4.6 allows an amount of 0 for shopping list items.
    var isFormValid: Bool {
        displayAmount >= 0 && (shoppingListEntry.productID != nil || !shoppingListEntry.note.isEmpty) && shoppingListEntry.shoppingListID != -1
    }

    var product: MDProduct? {
        mdProducts.first(where: { $0.id == shoppingListEntry.productID })
    }

    init(existingShoppingListEntry: ShoppingListItem? = nil, selectedShoppingListID: Int? = nil, productIDToSelect: Int? = nil, isPopup: Bool = false) {
        self.existingShoppingListEntry = existingShoppingListEntry
        self.selectedShoppingListID = selectedShoppingListID
        self.productIDToSelect = productIDToSelect
        self.isPopup = isPopup
        let entry = existingShoppingListEntry ?? ShoppingListItem(productID: productIDToSelect, shoppingListID: selectedShoppingListID ?? -1)
        self.shoppingListEntry = entry
        self._displayAmount = State(initialValue: entry.amount)
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
        if let product {
            shoppingListEntry.amount = QuantityUnitConversionResolver(product: product, conversions: mdQuantityUnitConversions).stockAmount(
                displayAmount,
                in: shoppingListEntry.quID
            )
        } else {
            // Free-text items keep the amount as entered, like Grocy's web form.
            shoppingListEntry.amount = displayAmount
        }
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
            if isSuccessful == false, let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            // Without multiple shopping lists, items always go to the first list (set when the form appears).
            if features.multipleShoppingLists {
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
            }

            ProductField(productID: $shoppingListEntry.productID, description: "Product")
                .onChange(of: shoppingListEntry.productID) {
                    if let selectedProduct = mdProducts.first(where: { $0.id == shoppingListEntry.productID }) {
                        shoppingListEntry.quID = selectedProduct.quIDPurchase
                    }
                }

            AmountSelectionView(productID: $shoppingListEntry.productID, amount: $displayAmount, quantityUnitID: $shoppingListEntry.quID)

            MyTextEditor(textToEdit: $shoppingListEntry.note, description: "Note", leadingIcon: MySymbols.note)
        }
        .formStyle(.grouped)
        .navigationTitle(existingShoppingListEntry == nil ? "Create shopping list item" : "Edit shopping list item")
        .task {
            await updateData()
            if shoppingListEntry.shoppingListID == -1 {
                shoppingListEntry.shoppingListID = shoppingListDescriptions.first?.id ?? -1
            }
            if shoppingListEntry.quID == nil, let selectedProduct = mdProducts.first(where: { $0.id == shoppingListEntry.productID }) {
                shoppingListEntry.quID = selectedProduct.quIDPurchase
            }
            // Only once: the task runs again when the form comes back from a picker, and would undo the person's edit.
            if !didLoadDisplayAmount {
                didLoadDisplayAmount = true
                if existingShoppingListEntry != nil {
                    displayAmount = shoppingListEntry.displayAmount(roundUp: false, product: product, conversions: mdQuantityUnitConversions)
                }
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
                            // Label style is left to the system, so the confirm button gets the standard Liquid Glass look.
                            // While it runs, the icon becomes an animated progress symbol. It stays an image: with a ProgressView as its icon,
                            // the item loses its icon and leaves iPhone Duo's vertical bar for a text-only button at the bottom.
                            Label("Save", systemImage: isProcessing ? MySymbols.progress : MySymbols.save)
                                .symbolEffect(.variableColor.iterative, isActive: isProcessing)
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
