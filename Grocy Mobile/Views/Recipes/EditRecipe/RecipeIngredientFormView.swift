//
//  RecipeIngredientFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 12.01.26.
//

import SwiftData
import SwiftUI

struct RecipeIngredientFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query var mdProducts: MDProducts
    @Query var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query var recipes: Recipes

    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingIngredient: RecipePos?
    var recipe: Recipe
    @State var ingredient: RecipePos
    /// The amount in the selected unit. Grocy stores `ingredient.amount` in the product's stock unit, so it's converted when saving.
    @State private var amount: Double
    @State private var didLoadAmount: Bool = false

    @State private var isFormCorrect: Bool = false
    private func checkFormCorrect() -> Bool {
        if ingredient.productID == nil { return false }
        if amount.isZero { return false }
        return true
    }

    private var product: MDProduct? {
        mdProducts.first(where: { $0.id == ingredient.productID })
    }

    init(existingIngredient: RecipePos? = nil, recipe: Recipe) {
        self.existingIngredient = existingIngredient
        self.recipe = recipe
        let ingredient = existingIngredient ?? RecipePos(recipeID: recipe.id)
        self.ingredient = ingredient
        self.amount = ingredient.amount
    }

    private let dataToUpdate: [ObjectEntities] = [.products, .quantity_units, .quantity_unit_conversions]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    /// Shows a saved ingredient's amount in its unit instead of the stock unit.
    private func loadAmount() {
        guard !didLoadAmount else { return }
        didLoadAmount = true
        guard existingIngredient != nil else { return }
        amount = RecipeAmountConversion.displayAmount(
            forStored: ingredient.amount,
            quID: ingredient.quID,
            onlyCheckSingleUnitInStock: ingredient.onlyCheckSingleUnitInStock,
            product: product,
            conversions: mdQuantityUnitConversions
        )
    }

    private func finishForm() {
        dismiss()
    }

    private func saveIngredient() async {
        if ingredient.id == -1 {
            do {
                ingredient.id = try grocyVM.findNextID(.recipes_pos)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        ingredient.amount = RecipeAmountConversion.storedAmount(
            for: amount,
            quID: ingredient.quID,
            onlyCheckSingleUnitInStock: ingredient.onlyCheckSingleUnitInStock,
            product: product,
            conversions: mdQuantityUnitConversions
        )
        do {
            try ingredient.modelContext?.save()
            if existingIngredient == nil {
                _ = try await grocyVM.postMDObject(object: .recipes_pos, content: ingredient)
            } else {
                try await grocyVM.putMDObjectWithID(object: .recipes_pos, id: ingredient.id, content: ingredient)
            }
            GrocyLogger.info("Ingredient \(ingredient.id) successful.")
            await grocyVM.requestData(objects: [.recipes_pos])
            isSuccessful = true
        } catch {
            GrocyLogger.error("Ingredient \(ingredient.id) failed. \(error)")
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
            if isSuccessful == false, let errorMessage = errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }

            ProductField(productID: $ingredient.productID, description: "Product")
                .onChange(of: ingredient.productID) {
                    ingredient.quID = product?.quIDConsume
                    isFormCorrect = checkFormCorrect()
                }

            MyToggle(
                isOn: $ingredient.onlyCheckSingleUnitInStock,
                description: "Only check if any amount is in stock",
                descriptionInfo: "A different amount/unit can then be used below while for stock fulfillment checking it is sufficient when any amount of the product in stock",
                icon: MySymbols.stockOverview
            )

            AmountSelectionView(productID: $ingredient.productID, amount: $amount, quantityUnitID: $ingredient.quID)
                .onChange(of: amount) {
                    isFormCorrect = checkFormCorrect()
                }

            MyTextField(
                textToEdit: $ingredient.variableAmount,
                description: "Variable amount",
                isCorrect: .constant(true),
                leadingIcon: MySymbols.amount,
                helpText: "When this is not empty, it will be shown instead of the amount entered above while the amount there will still be used for stock fulfillment checking"
            )

            MyToggle(
                isOn: $ingredient.roundUp,
                description: "Round up quantity amounts to the nearest whole number",
                icon: MySymbols.amount
            )

            MyToggle(
                isOn: $ingredient.notCheckStockFulfillment,
                description: "Disable stock fulfillment checking for this ingredient",
                icon: MySymbols.stockOverview
            )

            MyTextField(
                textToEdit: $ingredient.ingredientGroup,
                description: "Group",
                isCorrect: .constant(true),
                leadingIcon: MySymbols.groupBy,
                helpText: "This will be used as a headline to group ingredients together",
            )

            MyTextEditor(textToEdit: $ingredient.note, description: "Note", leadingIcon: MySymbols.description)

            MyDoubleStepper(amount: $ingredient.priceFactor, description: "Price factor", descriptionInfo: "The resulting price of this ingredient will be multiplied by this factor", systemImage: MySymbols.price)
        }
        .formStyle(.grouped)
        .task {
            // Convert with the cached data first, so the stock amount never shows up in the form
            loadAmount()
            await updateData()
            self.isFormCorrect = checkFormCorrect()
        }
        .navigationTitle(existingIngredient == nil ? "Add recipe ingredient" : "Edit recipe ingredient")
        .toolbar(content: {
            if existingIngredient == nil {
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
                                await saveIngredient()
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
                    .disabled(!isFormCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
            )
        })
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
        RecipeIngredientFormView(recipe: Recipe())
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        RecipeIngredientFormView(existingIngredient: RecipePos(), recipe: Recipe())
    }
}
