//
//  RecipeView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 23.11.23.
//

import SwiftData
import SwiftUI

// MARK: - Main View

struct RecipeView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query var mdQuantityUnits: MDQuantityUnits
    @Query var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query var mdProducts: MDProducts
    @Query var recipes: Recipes
    @Query private var ingredientsAll: [RecipePosResolvedElement]
    @Query private var fulfilments: RecipeFulfilments
    @Query private var nestings: RecipesNesting

    var initialRecipe: Recipe
    @State private var recipe: Recipe

    @State private var errorMessage: String? = nil
    @State private var isProcessing: Bool = false
    @State private var showConsumeAllNeeded: Bool = false
    @State private var showAddToShLSelection: Bool = false

    @State private var addToShLItems: [AddMissingToShLItem] = []

    /// The icon column of `RowIconLabelStyle`, to start a note under a row's title.
    @ScaledMetric(relativeTo: .body) private var rowIconWidth: CGFloat = Sizes.rowIconWidth

    private let dataToUpdate: [ObjectEntities] = [.quantity_units, .quantity_unit_conversions, .recipes, .recipes_pos_resolved, .recipes_nestings, .products]
    private let additionalDataToUpdate: [AdditionalEntities] = [.recipeFulfillments]

    init(initialRecipe: Recipe) {
        self.initialRecipe = initialRecipe
        self.recipe = initialRecipe
        let recipeID = initialRecipe.id
        // Queries instead of fetches in computed properties, so the ingredients appear as soon as the sync stored them.
        _ingredientsAll = Query(filter: #Predicate<RecipePosResolvedElement> { $0.recipeID == recipeID }, sort: \.productName)
        _fulfilments = Query(filter: #Predicate<RecipeFulfilment> { $0.recipeID == recipeID })
        _nestings = Query(filter: #Predicate<RecipeNesting> { $0.recipeID == recipeID }, sort: \.id)
    }

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    // MARK: Computed

    private var fulfilment: RecipeFulfilment? { fulfilments.first }

    /// Ingredient groups in display order: ungrouped ingredients first, then the groups by name.
    private var groupedIngredients: [(name: String, ingredients: [RecipePosResolvedElement])] {
        Dictionary(grouping: ingredientsAll) { $0.ingredientGroup ?? "" }
            .map { (name: $0.key, ingredients: $0.value.sorted { $0.productName.localizedStandardCompare($1.productName) == .orderedAscending }) }
            .sorted { lhs, rhs in
                if lhs.name.isEmpty != rhs.name.isEmpty { return lhs.name.isEmpty }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    /// Calories of all ingredients; Grocy calculates them per serving.
    private var summedCalories: Double { ingredientsAll.reduce(0) { $0 + $1.calories } }
    /// Costs of all ingredients for the desired servings.
    private var summedPrice: Double { ingredientsAll.reduce(0) { $0 + $1.costs } }
    private var pricePerServing: Double? {
        if let costsPerServing = fulfilment?.costsPerServing { return costsPerServing }
        return recipe.desiredServings > 0 ? summedPrice / recipe.desiredServings : nil
    }
    private var noPriceForOne: Bool { ingredientsAll.contains { $0.costs.isZero } }
    private var enoughInStock: Bool { ingredientsAll.allSatisfy(\.needFulfilled) }

    private var producedProduct: MDProduct? {
        guard let productID = recipe.productID else { return nil }
        return mdProducts.first { $0.id == productID }
    }

    private func quantityUnit(_ id: Int?) -> MDQuantityUnit? {
        guard let id else { return nil }
        return mdQuantityUnits.first { $0.id == id }
    }

    /// Grocy returns the amount in the product's stock unit. Shows it in the ingredient's own unit when a conversion exists.
    private func displayAmount(for ingredient: RecipePosResolvedElement) -> (amount: Double, unit: MDQuantityUnit?) {
        let product = mdProducts.first { $0.id == ingredient.productID }
        if ingredient.onlyCheckSingleUnitInStock {
            return (ingredient.recipeAmount, quantityUnit(ingredient.quID))
        }
        if let product, let factor = RecipeAmountConversion.factorFromStockUnit(to: ingredient.quID, product: product, conversions: mdQuantityUnitConversions) {
            return (ingredient.recipeAmount * factor, quantityUnit(ingredient.quID))
        }
        return (ingredient.recipeAmount, quantityUnit(product?.quIDStock ?? ingredient.quID))
    }

    // MARK: Actions

    func updateRecipe() async {
        isProcessing = true
        do {
            try recipe.modelContext?.save()
            try await grocyVM.putMDObjectWithID(object: .recipes, id: initialRecipe.id, content: recipe)
            GrocyLogger.info("Recipe \(recipe.name) amount update successful.")
            await updateData()
            errorMessage = nil
        } catch {
            GrocyLogger.error("Recipe \(recipe.name) amount update failed. \(error)")
            errorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
        }
        isProcessing = false
    }

    func consumeAllIngredientsNeeded() async {
        isProcessing = true
        do {
            try await grocyVM.consumeRecipe(recipeID: recipe.id)
            GrocyLogger.info("Consume all ingredients of recipe \(recipe.name) successful.")
            await updateData()
            errorMessage = nil
        } catch {
            GrocyLogger.error("Consume all ingredients of recipe \(recipe.name) failed. \(error)")
            errorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
        }
        isProcessing = false
    }

    func addMissingToShoppingList(excludedProductIds: [Int]) async {
        isProcessing = true
        do {
            try await grocyVM.addNotFulfilledProductsToShoppinglist(recipeID: recipe.id, content: RecipeAddToShLModel(excludedProductIds: excludedProductIds))
            GrocyLogger.info("Add not fulfilled products to shopping list for recipe \(recipe.name) successful.")
            await updateData()
            await grocyVM.requestData(objects: [.shopping_list])
            errorMessage = nil
        } catch {
            GrocyLogger.error("Add not fulfilled products to shopping list for recipe \(recipe.name) failed. \(error)")
            errorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
        }
        isProcessing = false
    }

    // MARK: Body

    /// A grouped Form on macOS (like the app's other detail and form screens there, with values in a trailing column);
    /// an inset grouped List on iOS, where it supports pull to refresh.
    @ViewBuilder
    private var container: some View {
        #if os(macOS)
            Form {
                listContent
            }
            .formStyle(.grouped)
        #else
            List {
                listContent
            }
            .listStyle(.insetGrouped)
        #endif
    }

    @ViewBuilder
    private var listContent: some View {
        if grocyVM.failedToLoadObjects.contains(where: { dataToUpdate.contains($0) }) {
            ServerProblemView()
                .listRowBackground(Color.clear)
        }

        if let pictureFileName = recipe.pictureFileName, !pictureFileName.isEmpty {
            Section {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: Sizes.recipeHeaderPictureMaxHeight)
                    .overlay {
                        PictureView(pictureFileName: pictureFileName, pictureType: .recipePictures)
                            .scaledToFill()
                    }
                    #if os(macOS)
                        // The grouped Form keeps the row insets on macOS, so round the picture like its group.
                        .clipShape(RoundedRectangle(cornerRadius: Sizes.recipeThumbnailCornerRadius, style: .continuous))
                    #else
                        .clipped()
                    #endif
                    .listRowInsets(EdgeInsets())
                    .accessibilityHidden(true)
            }
        }

        if let errorMessage {
            ErrorMessageView(errorMessage: errorMessage)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }

        overviewSection

        ForEach(groupedIngredients, id: \.name) { group in
            Section {
                ForEach(group.ingredients, id: \.id) { ingredient in
                    let display = displayAmount(for: ingredient)
                    RecipeIngredientRowView(
                        recipePos: ingredient,
                        amount: display.amount,
                        quantityUnit: display.unit,
                        stockQuantityUnit: quantityUnit(mdProducts.first { $0.id == ingredient.productID }?.quIDStock),
                        nestedRecipeName: ingredient.isNestedRecipePos ? recipes.first { $0.id == ingredient.childRecipeID }?.name : nil
                    )
                }
            } header: {
                if group.name.isEmpty {
                    Text("Ingredients")
                } else {
                    Text(group.name)
                }
            }
        }

        if !nestings.isEmpty {
            Section("Included recipes") {
                ForEach(nestings, id: \.id) { nesting in
                    if let includedRecipe = recipes.first(where: { $0.id == nesting.includesRecipeID }) {
                        NavigationLink {
                            RecipeView(initialRecipe: includedRecipe)
                        } label: {
                            LabeledContent {
                                Text(nesting.servings.formattedAmount)
                            } label: {
                                Label(includedRecipe.name, systemImage: MySymbols.recipe)
                            }
                        }
                    }
                }
            }
        }

        if !recipe.recipeDescription.isEmpty {
            Section("Preparation") {
                HTMLPreviewView(htmlContent: $recipe.recipeDescription)
            }
        }
    }

    var body: some View {
        container
        .navigationTitle(recipe.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    showConsumeAllNeeded.toggle()
                } label: {
                    Label("Consume all ingredients needed by this recipe", systemImage: MySymbols.consume)
                }
                Button {
                    showAddToShLSelection.toggle()
                } label: {
                    Label("Put missing products on shopping list", systemImage: MySymbols.addToShoppingList)
                }
                .disabled(enoughInStock)
            }
        }
        // Short title, details in the message, buttons named after the result instead of "Yes"/"No" (HIG).
        .alert(
            "Consume all ingredients needed by this recipe",
            isPresented: $showConsumeAllNeeded,
            actions: {
                Button("Cancel", role: .cancel) {}
                // No destructive role: the person chose to consume, this button carries out their intent.
                Button("Consume") {
                    Task {
                        await consumeAllIngredientsNeeded()
                    }
                }
            },
            message: {
                Text(
                    "\(Text("Are you sure you want to consume all ingredients needed by recipe \"\(recipe.name)\" (ingredients marked with \"only check if any amount is in stock\" will be ignored)?"))\n\n\(Text("For ingredients that are only partially in stock, the in stock amount will be consumed."))"
                )
            }
        )
        .sheet(isPresented: $showAddToShLSelection) {
            NavigationStack {
                List {
                    Text("Are you sure you want to put all missing ingredients for recipe \"\(recipe.name)\" on the shopping list?")
                        .font(.headline)

                    Text("Uncheck ingredients to not put them on the shopping list")
                        .font(.subheadline)

                    Section {
                        ForEach($addToShLItems) { $item in
                            Toggle(item.label, isOn: $item.isChecked)
                        }
                    }
                }
                .onAppear {
                    addToShLItems = []
                    let missingIngredients = ingredientsAll.filter({
                        !$0.needFulfilled && !$0.needFulfilledWithShoppingList
                    })
                    for ingredient in missingIngredients {
                        addToShLItems.append(
                            AddMissingToShLItem(
                                id: ingredient.productID,
                                label: ingredient.productName
                            )
                        )
                    }
                }
                .toolbar {
                    ToolbarItem(
                        placement: .cancellationAction,
                        content: {
                            Button(role: .cancel, action: { showAddToShLSelection = false })
                        }
                    )
                    ToolbarItem(
                        placement: .confirmationAction,
                        content: {
                            Button(
                                role: .confirm,
                                action: {
                                    var excludedProductIds: [Int] = []
                                    for item in addToShLItems {
                                        if !item.isChecked {
                                            excludedProductIds.append(item.id)
                                        }
                                    }
                                    Task {
                                        await addMissingToShoppingList(excludedProductIds: excludedProductIds)
                                    }
                                    showAddToShLSelection = false
                                }
                            )
                        }
                    )
                }
            }
        }
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
    }
}

// MARK: - Overview

extension RecipeView {
    @ViewBuilder
    private var fulfilmentLabel: some View {
        if enoughInStock {
            Label {
                Text("Enough in stock")
            } icon: {
                Image(systemName: MySymbols.fulfilled)
                    .foregroundStyle(Color(.GrocyColors.grocyGreen))
            }
        } else if fulfilment?.needFulfilledWithShoppingList == true {
            Label {
                Text("Not enough in stock, \(fulfilment?.missingProductsCount ?? 0) ingredient missing but already on the shopping list")
            } icon: {
                Image(systemName: MySymbols.partiallyFulfilled)
                    .foregroundStyle(Color(.GrocyColors.grocyYellow))
            }
        } else {
            Label {
                Text("Not enough in stock, \(fulfilment?.missingProductsCount ?? ingredientsAll.filter { !$0.needFulfilled }.count) ingredient missing")
            } icon: {
                Image(systemName: MySymbols.notFulfilled)
                    .foregroundStyle(Color(.GrocyColors.grocyRed))
            }
        }
    }

    /// A row title with a help button behind the title.
    private func labelWithHelp(_ title: LocalizedStringKey, systemImage: String, help: LocalizedStringKey) -> some View {
        Label {
            HStack {
                Text(title)
                FieldDescription(description: help)
            }
        } icon: {
            Image(systemName: systemImage)
        }
    }

    private var overviewSection: some View {
        Section {
            if !ingredientsAll.isEmpty {
                fulfilmentLabel
            }

            MyDoubleStepper(
                amount: $recipe.desiredServings,
                description: "Desired servings",
                systemImage: MySymbols.servings
            )
            .onChange(of: recipe.desiredServings) {
                Task { await updateRecipe() }
            }

            LabeledContent {
                Text(recipe.baseServings.formattedAmount)
            } label: {
                labelWithHelp("Servings", systemImage: MySymbols.servings, help: "The ingredients listed here result in this amount of servings")
            }

            LabeledContent {
                Text("\(summedCalories.formattedAmount) kcal")
                    .monospacedDigit()
            } label: {
                labelWithHelp("Energy", systemImage: MySymbols.energy, help: "per serving")
            }

            if let dueScore = fulfilment?.dueScore {
                LabeledContent {
                    Text("\(dueScore)")
                        .monospacedDigit()
                } label: {
                    Label("Due score", systemImage: MySymbols.due)
                }
            }

            if let producedProduct {
                LabeledContent {
                    Text(producedProduct.name)
                } label: {
                    Label("Produces product", systemImage: MySymbols.selfProduction)
                }
            }

            // The note about missing prices belongs to the costs, so it's in the same row, below the label and the price.
            // Not in the LabeledContent's label: a long label pushes the price out of the trailing column.
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                LabeledContent {
                    VStack(alignment: .trailing, spacing: Spacing.xxSmall) {
                        Text(grocyVM.getFormattedCurrency(amount: summedPrice))
                            .monospacedDigit()
                        if let pricePerServing {
                            Text("\(grocyVM.getFormattedCurrency(amount: pricePerServing)) \(Text("per serving"))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                } label: {
                    labelWithHelp("Costs", systemImage: MySymbols.price, help: "Based on the prices of the default consume rule (Opened first, then first due first, then first in first out) for in stock ingredients and on the last price for missing ones")
                }
                if noPriceForOne {
                    Text("No price information is available for at least one ingredient")
                        .font(.caption)
                        .foregroundStyle(Color(.GrocyColors.grocyRed))
                        .padding(.leading, rowIconWidth + Spacing.medium)
                }
            }
        }
        // One icon column for all rows, also for the Labels inside the stepper and the costs row.
        .labelStyle(.rowIcon)
        // The List tints the icons of some rows with the accent color; keep all row icons in the text color, in one color each.
        .listItemTint(Color.primary)
        .symbolRenderingMode(.monochrome)
    }
}

// MARK: - Preview

#Preview(traits: .previewData) {
    NavigationStack {
        RecipeView(initialRecipe: Recipe(name: "Recipe 1", recipeDescription: "<h1>Hello</h1>"))
    }
}

#Preview("Recipe with ingredients", traits: .previewData) {
    @Previewable @Query(filter: #Predicate<Recipe> { $0.id == 1 }) var recipes: Recipes
    NavigationStack {
        if let recipe = recipes.first {
            RecipeView(initialRecipe: recipe)
        }
    }
}
