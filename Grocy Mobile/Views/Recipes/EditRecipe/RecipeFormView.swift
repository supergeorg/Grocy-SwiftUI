//
//  RecipeFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 12.01.26.
//

import SwiftData
import SwiftUI

enum RecipeFormInteraction: Hashable, Identifiable {
    case editIngredient(ingredient: RecipePos, recipe: Recipe)
    case editNesting(nesting: RecipeNesting, recipeID: Int)

    var id: Self { self }
}

struct RecipeFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @Query var mdProducts: MDProducts
    @Query var mdQuantityUnits: MDQuantityUnits
    @Query var recipes: Recipes

    @Environment(\.dismiss) var dismiss

    @AppStorage("useAppleIntelligence") var useAppleIntelligence: Bool = true
    @AppStorage("devMode") private var devMode: Bool = false

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil
    @State private var isPictureExpanded: Bool = false
    @State private var isPreparationExpanded: Bool = false

    @State private var continueEditing: Bool = false

    @State private var showAddRecipeIngredient: Bool = false
    @State private var showAddNestedRecipe: Bool = false
    @State private var showPreparationEditor: Bool = false

    @State private var existingRecipe: Recipe?
    @State private var recipe: Recipe
    @State private var createdRecipeID: Int? = nil

    var groupedRecipes: [String: [RecipePos]] {
        let sortDescriptor = SortDescriptor<RecipePos>(\.ingredientGroup)
        let predicate = #Predicate<RecipePos> { recipePos in
            recipePos.recipeID == recipe.id
        }

        let descriptor = FetchDescriptor<RecipePos>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )

        let matchingRecipes = (try? modelContext.fetch(descriptor)) ?? []

        var groupedRecipes: [String: [RecipePos]] = [:]
        for recipePos in matchingRecipes {
            if groupedRecipes[recipePos.ingredientGroup] == nil {
                groupedRecipes[recipePos.ingredientGroup] = []
            }
            groupedRecipes[recipePos.ingredientGroup]?.append(recipePos)
        }
        return groupedRecipes
    }

    var nestedRecipes: RecipesNesting {
        let sortDescriptor = SortDescriptor<RecipeNesting>(\.recipeID)
        let predicate = #Predicate<RecipeNesting> { nesting in
            nesting.recipeID == recipe.id
        }

        let descriptor = FetchDescriptor<RecipeNesting>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    @State private var isFormCorrect: Bool = false
    private func checkFormCorrect() -> Bool {
        let foundRecipe = recipes.first(where: { $0.name == recipe.name })
        return !(recipe.name.isEmpty || (foundRecipe != nil && foundRecipe!.id != recipe.id)) && recipe.baseServings > 0
    }

    init(existingRecipe: Recipe? = nil) {
        _existingRecipe = State(initialValue: existingRecipe)
        _recipe = State(initialValue: existingRecipe ?? Recipe())
    }

    private let dataToUpdate: [ObjectEntities] = [.products, .recipes_nestings, .recipes_pos, .quantity_units]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func finishForm() {
        dismiss()
    }

    private func saveRecipe() async {
        if recipe.id == -1 {
            do {
                recipe.id = try grocyVM.findNextID(.recipes)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        do {
            try recipe.modelContext?.save()
            if existingRecipe == nil {
                let successfulCreationMessage = try await grocyVM.postMDObject(object: .recipes, content: recipe)
                createdRecipeID = successfulCreationMessage.createdObjectID
            } else {
                try await grocyVM.putMDObjectWithID(object: .recipes, id: recipe.id, content: recipe)
            }
            GrocyLogger.info("Recipe \(recipe.name) successful.")
            await grocyVM.requestData(objects: [.recipes])
            isSuccessful = true
        } catch {
            GrocyLogger.error("Recipe \(recipe.name) failed. \(error)")
            isSuccessful = false
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isProcessing = false
    }

    private func deleteNesting(nestingToDelete: RecipeNesting) async {
        do {
            try await grocyVM.deleteMDObject(object: .recipes_nestings, id: nestingToDelete.id)
            GrocyLogger.info("Deleting recipe nesting was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Deleting recipe nesting failed. \(error)")
        }
    }

    private func deleteIngredient(ingredientToDelete: RecipePos) async {
        do {
            try await grocyVM.deleteMDObject(object: .recipes_pos, id: ingredientToDelete.id)
            GrocyLogger.info("Deleting ingredient was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Deleting ingredient failed. \(error)")
        }
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage = errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            MyTextField(
                textToEdit: $recipe.name,
                description: "Name",
                prompt: "Required",
                isCorrect: $isFormCorrect,
                leadingIcon: MySymbols.name,
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: recipe.name) {
                isFormCorrect = checkFormCorrect()
            }
            MyDoubleStepper(amount: $recipe.baseServings, description: "Servings", descriptionInfo: "The ingredients listed here result in this amount of servings", minAmount: 0.0000001, systemImage: MySymbols.amount)

            MyToggle(
                isOn: $recipe.notCheckShoppinglist,
                description: "Do not check against the shopping list when adding missing items to it",
                descriptionInfo:
                    "By default the amount to be added to the shopping list is \"needed amount - stock amount - shopping list amount\" - when this is enabled, it is only checked against the stock amount, not against what is already on the shopping list",
                icon: MySymbols.shoppingList,
            )

            ProductField(productID: $recipe.productID, description: "Produces product", descriptionInfo: "When a product is selected, one unit (per serving in stock quantity unit) will be added to stock on consuming this recipe")

            if existingRecipe != nil {
                if devMode && useAppleIntelligence && AppleIntelligenceStatus.isAppleIntelligenceAvailable {
                    Section("Import Recipe") {

                    }
                }

                Section(
                    content: {
                        ForEach(groupedRecipes.sorted(by: { $0.key < $1.key }), id: \.key) { (groupName, ingredients) in
                            Section {
                                ForEach(ingredients, id: \.id) { ingredient in
                                    NavigationLink(
                                        value: RecipeFormInteraction.editIngredient(ingredient: ingredient, recipe: recipe),
                                        label: {
                                            RecipeFormIngredientRowView(recipePos: ingredient, product: mdProducts.first(where: { $0.id == ingredient.productID }), quantityUnit: mdQuantityUnits.first(where: { $0.id == ingredient.quID }))
                                        }
                                    )
                                    .swipeActions(
                                        edge: .trailing,
                                        allowsFullSwipe: true,
                                        content: {
                                            Button(
                                                role: .destructive,
                                                action: {
                                                    Task {
                                                        await deleteIngredient(ingredientToDelete: ingredient)
                                                    }
                                                },
                                                label: { Label("Delete", systemImage: MySymbols.delete) }
                                            )
                                        }
                                    )
                                }
                            } header: {
                                if !groupName.isEmpty {
                                    Text(groupName)
                                        .font(.headline)
                                        .italic()
                                }
                            }
                        }
                    },
                    header: {
                        VStack(alignment: .leading) {
                            HStack(alignment: .top) {
                                Text("Ingredients list")
                                Spacer()
                                Button(
                                    action: {
                                        showAddRecipeIngredient.toggle()
                                    },
                                    label: {
                                        Label("Add", systemImage: MySymbols.new)
                                    }
                                )
                            }
                        }
                    }
                )

                Section(
                    content: {
                        ForEach(nestedRecipes.sorted(by: { $0.recipeID < $1.recipeID }), id: \.id) { nesting in
                            NavigationLink(
                                value: RecipeFormInteraction.editNesting(nesting: nesting, recipeID: nesting.includesRecipeID),
                                label: {
                                    NestedRecipeRowView(nesting: nesting, recipe: recipes.first(where: { $0.id == nesting.includesRecipeID }))
                                }
                            )
                            .swipeActions(
                                edge: .trailing,
                                allowsFullSwipe: true,
                                content: {
                                    Button(
                                        role: .destructive,
                                        action: {
                                            Task {
                                                await deleteNesting(nestingToDelete: nesting)
                                            }
                                        },
                                        label: { Label("Delete", systemImage: MySymbols.delete) }
                                    )
                                }
                            )
                        }
                    },
                    header: {
                        VStack(alignment: .leading) {
                            HStack(alignment: .top) {
                                Text("Included recipes")
                                Spacer()
                                Button(
                                    action: {
                                        showAddNestedRecipe.toggle()
                                    },
                                    label: {
                                        Label("Add", systemImage: MySymbols.new)
                                    }
                                )
                            }
                        }
                    }
                )

                Section {
                    DisclosureGroup(
                        isExpanded: $isPictureExpanded,
                        content: {
                            RecipePictureView(existingRecipe: recipe, pictureFileName: $recipe.pictureFileName)
                        },
                        label: {
                            Label("Picture", systemImage: MySymbols.picture)
                                .foregroundStyle(.primary)
                        }
                    )
                }
            }

            Section {
                DisclosureGroup(
                    isExpanded: $isPreparationExpanded,
                    content: {
                        List {
                            ScrollView(.vertical) {
                                HTMLPreviewView(htmlContent: $recipe.recipeDescription)
                            }

                            Button(action: {
                                showPreparationEditor.toggle()
                            }) {
                                Label("Edit", systemImage: "pencil.and.scribble")
                            }
                        }
                    },
                    label: {
                        Label("Preparation", systemImage: MySymbols.description)
                            .foregroundStyle(.primary)
                    }
                )
            }
        }
        .formStyle(.grouped)
        .navigationDestination(for: RecipeFormInteraction.self) { interaction in
            switch interaction {
            case .editIngredient(let ingredient, let recipe):
                RecipeIngredientFormView(existingIngredient: ingredient, recipe: recipe)
            case .editNesting(let nesting, let recipeID):
                NestedRecipeFormView(existingRecipeNesting: nesting, recipeID: recipeID)
            }
        }
        .task {
            await updateData()
            self.isFormCorrect = checkFormCorrect()
        }
        .navigationTitle(existingRecipe == nil ? "Create recipe" : "Edit recipe")
        .sheet(
            isPresented: $showAddRecipeIngredient,
            content: {
                NavigationStack {
                    RecipeIngredientFormView(recipe: recipe)
                }
            }
        )
        .sheet(
            isPresented: $showAddNestedRecipe,
            content: {
                NavigationStack {
                    NestedRecipeFormView(recipeID: recipe.id)
                }
            }
        )
        .sheet(
            isPresented: $showPreparationEditor,
            content: {
                RecipePreparationEditorView(htmlContent: $recipe.recipeDescription)
            }
        )
        .toolbar(content: {
            if existingRecipe == nil || continueEditing == true {
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
            ToolbarItemGroup(
                placement: .confirmationAction,
                content: {
                    Button(
                        role: .confirm,
                        action: {
                            continueEditing = false
                            Task {
                                await saveRecipe()
                            }
                        },
                        label: {
                            if !isProcessing {
                                Label("Save & return to recipes", systemImage: MySymbols.save)
                                    .labelStyle(.titleAndIcon)
                            } else {
                                ProgressView().progressViewStyle(.circular)
                            }
                        }
                    )
                    .disabled(!isFormCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)

                    if existingRecipe == nil {
                        Button(
                            role: .confirm,
                            action: {
                                continueEditing = true
                                Task {
                                    await saveRecipe()
                                }
                            },
                            label: {
                                if !isProcessing {
                                    Label("Save & continue", systemImage: MySymbols.forward)
                                        .labelStyle(.titleAndIcon)
                                } else {
                                    ProgressView().progressViewStyle(.circular)
                                }
                            }
                        )
                        .disabled(!isFormCorrect || isProcessing)
                    }
                }
            )
        })
        .onChange(of: isSuccessful) {
            guard isSuccessful == true else { return }
            if continueEditing,
                let createdID = createdRecipeID,
                let found = recipes.first(where: { $0.id == createdID })
            {
                existingRecipe = found
                recipe = found
            } else if !continueEditing {
                finishForm()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        RecipeFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        RecipeFormView(existingRecipe: Recipe(name: "Recipe"))
    }
}
