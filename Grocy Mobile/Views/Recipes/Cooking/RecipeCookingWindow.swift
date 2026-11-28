//
//  RecipeCookingWindow.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 28.11.26.
//

import SwiftData
import SwiftUI

#if os(macOS)
    /// The cooking mode in a window of its own on the Mac, so the recipe and the rest of the app stay usable next to it.
    /// Opened with the recipe's ID (`openWindow(id: AppWindow.cooking, value:)`), one window per recipe.
    struct RecipeCookingWindow: View {
        @Query private var recipes: Recipes

        private let recipeID: Int?

        init(recipeID: Int?) {
            self.recipeID = recipeID
            let id = recipeID ?? -1
            _recipes = Query(filter: #Predicate<Recipe> { $0.id == id })
        }

        var body: some View {
            if let recipe = recipes.first {
                RecipeCookingView(recipe: recipe, readyIngredients: MiseEnPlaceStore.shared.binding(for: recipe.id))
            } else {
                // E.g. a window restored at launch for a recipe that was deleted meanwhile.
                ContentUnavailableView("Recipe not found", systemImage: MySymbols.recipe)
                    .frame(minWidth: Constants.macOSCookingMinWidth, minHeight: Constants.macOSCookingMinHeight)
            }
        }
    }
#endif
