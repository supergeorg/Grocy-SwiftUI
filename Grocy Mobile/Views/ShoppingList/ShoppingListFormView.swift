//
//  ShoppingListAddView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftData
import SwiftUI

struct ShoppingListFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(sort: \ShoppingListDescription.id, order: .forward) var shoppingListDescriptions: ShoppingListDescriptions

    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingShoppingListDescription: ShoppingListDescription?
    @State var shoppingListDescription: ShoppingListDescription

    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        guard !shoppingListDescription.name.isEmpty else { return false }
        if let foundShoppingListDescription = shoppingListDescriptions.first(where: { $0.name == shoppingListDescription.name }) {
            guard foundShoppingListDescription.id == shoppingListDescription.id else { return false }
        }
        return true
    }

    init(existingShoppingListDescription: ShoppingListDescription? = nil) {
        self.existingShoppingListDescription = existingShoppingListDescription
        self.shoppingListDescription = existingShoppingListDescription ?? ShoppingListDescription()
    }

    private func finishForm() {
        self.dismiss()
    }

    private func updateData() async {
        await grocyVM.requestData(objects: [.shopping_lists])
    }

    func saveShoppingList() async {
        if shoppingListDescription.id == -1 {
            do {
                shoppingListDescription.id = try grocyVM.findNextID(.shopping_lists)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        do {
            try shoppingListDescription.modelContext?.save()
            if existingShoppingListDescription == nil {
                _ = try await grocyVM.postMDObject(object: .shopping_lists, content: shoppingListDescription)
            } else {
                try await grocyVM.putMDObjectWithID(object: .shopping_lists, id: shoppingListDescription.id, content: shoppingListDescription)
            }
            GrocyLogger.info("Shopping list \(shoppingListDescription.name) successful.")
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Shopping list \(shoppingListDescription.name) failed. \(error)")
            isSuccessful = false
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            MyTextField(
                textToEdit: $shoppingListDescription.name,
                description: "Name",
                isCorrect: $isNameCorrect,
                leadingIcon: MySymbols.name,
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: shoppingListDescription.name) {
                isNameCorrect = checkNameCorrect()
            }
        }
        .formStyle(.grouped)
        .navigationTitle(existingShoppingListDescription == nil ? "Create shopping list" : "Edit shopping list")
        .task {
            await updateData()
            self.isNameCorrect = checkNameCorrect()
        }
        .toolbar {
            if existingShoppingListDescription == nil {
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
                                await saveShoppingList()
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
                    .disabled(!isNameCorrect || isProcessing)
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
        ShoppingListFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        ShoppingListFormView(existingShoppingListDescription: ShoppingListDescription(id: 1, name: "Shopping list"))
    }
}
