//
//  RecipeView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 23.11.23.
//

import SwiftData
import SwiftUI
import WebKit

struct RecipeView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @Query var mdQuantityUnits: MDQuantityUnits
    @Query var mdProducts: MDProducts

    var initialRecipe: Recipe
    @State private var recipe: Recipe
    
    @State private var errorMessage: String? = nil
    @State private var isProcessing: Bool = false

    @State private var page = WebPage()
    let blank = URL(string: "about:blank")!

    @State private var desiredServings: Double = 1.0

    private let dataToUpdate: [ObjectEntities] = [.quantity_units, .recipes_pos_resolved, .products]
    private let additionalDataToUpdate: [AdditionalEntities] = []
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    init(initialRecipe: Recipe) {
        self.initialRecipe = initialRecipe
        self.recipe = initialRecipe
    }

    var ingredientsAll: [RecipePosResolvedElement] {
        let sortDescriptor = SortDescriptor<RecipePosResolvedElement>(\.ingredientGroup)
        let predicate = #Predicate<RecipePosResolvedElement> { recipePos in
            recipePos.recipeID == recipe.id
        }

        let descriptor = FetchDescriptor<RecipePosResolvedElement>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var groupedIngredients: [String: [RecipePosResolvedElement]] {
        var groupedIngredients: [String: [RecipePosResolvedElement]] = [:]
        for recipePos in ingredientsAll {
            let ingredientGroup = recipePos.ingredientGroup ?? ""
            if groupedIngredients[ingredientGroup] == nil {
                groupedIngredients[ingredientGroup] = []
            }
            groupedIngredients[ingredientGroup]?.append(recipePos)
        }
        return groupedIngredients
    }

    var posResCount: Int {
        var descriptor = FetchDescriptor<RecipePosResolvedElement>(
            sortBy: []
        )
        descriptor.fetchLimit = 0

        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    var summedCalories: Double {
        var sumOfCalories: Double = 0

        for recipe in ingredientsAll {
            sumOfCalories += recipe.calories
        }

        return sumOfCalories
    }

    var summedPrice: Double {
        var sumOfPrice: Double = 0

        for recipe in ingredientsAll {
            sumOfPrice += recipe.costs
        }

        return sumOfPrice
    }
    var noPriceForOne: Bool {
        var noPrice: Bool = false
        for recipe in ingredientsAll {
            if recipe.costs.isZero {
                noPrice = true
            }
        }
        return noPrice
    }
    
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
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isProcessing = false
    }

    var body: some View {
        //        ScrollView(.vertical) {
        //            VStack(alignment: .leading) {
        //                if let pictureFileName = recipe.pictureFileName {
        //                    PictureView(pictureFileName: pictureFileName, pictureType: .recipePictures)
        //                        .backgroundExtensionEffect()
        //                }

        List {
            if let errorMessage = errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            Section {
                MyDoubleStepper(amount: $recipe.desiredServings, description: "Desired servings", systemImage: MySymbols.amount)
                    .onChange(of: recipe.desiredServings, {
                        Task {
                            await updateRecipe()
                        }
                    })
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                LabeledContent(
                    content: {
                        Text("\(summedCalories.formattedAmount) kcal")
                    },
                    label: {
                        Label(
                            title: {
                                HStack {
                                    Text("Energy")
                                    FieldDescription(description: "per serving")
                                }
                            },
                            icon: {
                                Image(systemName: MySymbols.energy)
                            }
                        )
                    }
                )
                .foregroundStyle(.primary)
                VStack(alignment: .leading, spacing: 5.0) {
                    LabeledContent(
                        content: {
                            Text(grocyVM.getFormattedCurrency(amount: summedPrice))
                        },
                        label: {
                            Label(
                                title: {
                                    HStack {
                                        Text("Costs")
                                        FieldDescription(
                                            description: "Based on the prices of the default consume rule (Opened first, then first due first, then first in first out) for in stock ingredients and on the last price for missing ones"
                                        )
                                    }
                                },
                                icon: {
                                    Image(systemName: MySymbols.price)
                                }
                            )
                        }
                    )
                    .foregroundStyle(.primary)
                    if noPriceForOne {
                        Text("No price information is available for at least one ingredient")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            Section("Ingredients") {
                ForEach(groupedIngredients.sorted(by: { $0.key < $1.key }), id: \.key) { (groupName, ingredients) in
                    Section {
                        ForEach(ingredients.sorted(by: { $0.productName < $1.productName }), id: \.id) { ingredient in
                            RecipeIngredientRowView(recipePos: ingredient, quantityUnit: mdQuantityUnits.first(where: { $0.id == mdProducts.first(where: { $0.id == ingredient.productID })?.quIDStock }))
                        }
                    } header: {
                        if !groupName.isEmpty {
                            Text(groupName)
                                .font(.headline)
                                .italic()
                        }
                    }
                }
            }
            Section(
                "Preparation",
                content: {
                    WebView(page)
                        .aspectRatio(contentMode: .fit)
                        .onAppear {
                            page.load(html: recipe.recipeDescription, baseURL: blank)
                        }
                }
            )
        }
        .navigationTitle(recipe.name)
        .task {
            await updateData()
        }
    }
}

#Preview {
    NavigationStack {
        RecipeView(initialRecipe: Recipe(name: "Recipe 1", recipeDescription: "<h1>Hello</h1>"))
    }
}
