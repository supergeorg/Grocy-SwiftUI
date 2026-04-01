//
//  RecipeView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 23.11.23.
//

import SwiftData
import SwiftUI
import WebKit

// MARK: - Stat Chip

private struct StatChip: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    var warning: LocalizedStringKey? = nil
    var info: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text(value)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
                Spacer()
                FieldDescription(description: info)
            }
            if let warning {
                Text(warning)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Settings Card

private struct SettingsCard: View {
    @Binding var recipe: Recipe
    let summedCalories: Double
    let summedPrice: String
    let noPriceForOne: Bool
    let isProcessing: Bool
    let onServingsChange: () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            MyDoubleStepper(
                amount: $recipe.desiredServings,
                description: "Desired servings",
                systemImage: MySymbols.amount
            )
            .onChange(of: recipe.desiredServings) {
                Task { await onServingsChange() }
            }

            if isProcessing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: 12) {
                StatChip(
                    icon: MySymbols.energy,
                    title: "Energy",
                    value: "\(summedCalories.formattedAmount) kcal",
                    info: "Based on the prices of the default consume rule (Opened first, then first due first, then first in first out) for in stock ingredients and on the last price for missing ones"
                )
                StatChip(
                    icon: MySymbols.price,
                    title: "Costs",
                    value: summedPrice,
                    warning: noPriceForOne
                        ? "No price information is available for at least one ingredient"
                        : nil,
                    info: "per serving"
                )
            }
        }
        .padding(18)
        .glassEffect(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Main View

struct RecipeView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @Query var mdQuantityUnits: MDQuantityUnits
    @Query var mdProducts: MDProducts

    var initialRecipe: Recipe
    @State private var recipe: Recipe

    @State private var errorMessage: String? = nil
    @State private var isProcessing: Bool = false
    @State private var showConsumeAllNeeded: Bool = false
    @State private var showAddToShLSelection: Bool = false

    @State private var addToShLItems: [AddMissingToShLItem] = []

    @State private var page = WebPage()
    private let blank = URL(string: "about:blank")!

    private let dataToUpdate: [ObjectEntities] = [.quantity_units, .recipes_pos_resolved, .products]
    private let additionalDataToUpdate: [AdditionalEntities] = []

    init(initialRecipe: Recipe) {
        self.initialRecipe = initialRecipe
        self.recipe = initialRecipe
    }

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    // MARK: Computed

    var ingredientsAll: [RecipePosResolvedElement] {
        let descriptor = FetchDescriptor<RecipePosResolvedElement>(
            predicate: #Predicate { $0.recipeID == recipe.id },
            sortBy: [SortDescriptor(\.ingredientGroup)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var groupedIngredients: [String: [RecipePosResolvedElement]] {
        Dictionary(grouping: ingredientsAll) { $0.ingredientGroup ?? "" }
    }

    var summedCalories: Double { ingredientsAll.reduce(0) { $0 + $1.calories } }
    var summedPrice: Double { ingredientsAll.reduce(0) { $0 + $1.costs } }
    var noPriceForOne: Bool { ingredientsAll.contains { $0.costs.isZero } }
    var enoughInStock: Bool { ingredientsAll.allSatisfy(\.needFulfilled) }

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

    var body: some View {
        List {
            if let pictureFileName = recipe.pictureFileName {
                PictureView(pictureFileName: pictureFileName, pictureType: .recipePictures)
                    .backgroundExtensionEffect()
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            if let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            Section {
                SettingsCard(
                    recipe: $recipe,
                    summedCalories: summedCalories,
                    summedPrice: grocyVM.getFormattedCurrency(amount: summedPrice),
                    noPriceForOne: noPriceForOne,
                    isProcessing: isProcessing,
                    onServingsChange: updateRecipe
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            ForEach(
                groupedIngredients.sorted(by: { $0.key < $1.key }),
                id: \.key
            ) { groupName, ingredients in
                Section {
                    ForEach(
                        ingredients.sorted(by: { $0.productName < $1.productName }),
                        id: \.id
                    ) { ingredient in
                        RecipeIngredientRowView(
                            recipePos: ingredient,
                            quantityUnit: mdQuantityUnits.first(where: { $0.id == mdProducts.first(where: { $0.id == ingredient.productID })?.quIDStock })
                        )
                    }
                } header: {
                    if groupName.isEmpty {
                        Text("Ingredients")
                            .font(.title)
                    } else {
                        Text(groupName)
                    }
                }
            }
            Section {
                HTMLPreviewView(htmlContent: $recipe.recipeDescription)
            } header: {
                Text("Preparation")
                    .font(.title)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
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
        .alert(
            Text(
                "\(Text("Are you sure you want to consume all ingredients needed by recipe \"\(recipe.name)\" (ingredients marked with \"only check if any amount is in stock\" will be ignored)?"))\n\n\(Text("For ingredients that are only partially in stock, the in stock amount will be consumed."))"
            ),
            isPresented: $showConsumeAllNeeded,
            actions: {
                Button("No", role: .cancel) {}
                Button("Yes", role: .destructive) {
                    Task {
                        await consumeAllIngredientsNeeded()
                    }
                }
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

// MARK: - Preview

#Preview(traits: .previewData) {
    NavigationStack {
        RecipeView(initialRecipe: Recipe(name: "Recipe 1", recipeDescription: "<h1>Hello</h1>"))
    }
}
