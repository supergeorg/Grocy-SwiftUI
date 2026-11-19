//
//  StockProductRecipesView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import SwiftData
import SwiftUI

/// The recipes that use a product as an ingredient, opened from the stock menu.
struct StockProductRecipesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(sort: \Recipe.name, order: .forward) private var recipes: Recipes
    @Query private var ingredients: [RecipePos]
    @Query private var fulfillments: RecipeFulfilments

    var stockElement: StockElement

    private let dataToUpdate: [ObjectEntities] = [.recipes, .recipes_pos]
    private let additionalDataToUpdate: [AdditionalEntities] = [.recipeFulfillments]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    /// Normal recipes (no meal plan days) with the product as an ingredient.
    private var recipesWithProduct: Recipes {
        let recipeIDs = Set(ingredients.filter { $0.productID == stockElement.productID }.map(\.recipeID))
        return recipes.filter { $0.type == .normal && recipeIDs.contains($0.id) }
    }

    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.contains(where: dataToUpdate.contains) {
                ServerProblemView()
            } else if recipesWithProduct.isEmpty {
                ContentUnavailableView(
                    "No recipes found",
                    systemImage: MySymbols.recipe,
                    description: Text("No recipe uses \(stockElement.product?.name ?? "this product").")
                )
            }
            ForEach(recipesWithProduct, id: \.id) { recipe in
                NavigationLink(value: recipe) {
                    RecipeRowView(recipe: recipe, fulfillment: fulfillments.first(where: { $0.recipeID == recipe.id }))
                }
            }
        }
        .navigationTitle("Recipes with \(stockElement.product?.name ?? "")")
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeView(initialRecipe: recipe)
        }
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        StockProductRecipesView(stockElement: StockElement(productID: 1, product: MDProduct(id: 1, name: "Cookies")))
    }
}
