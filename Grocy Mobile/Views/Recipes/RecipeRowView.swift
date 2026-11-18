//
//  RecipeRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 02.12.22.
//

import SwiftUI

/// A recipe in the list layout of the recipe overview: a small picture, the name, the stock status and a few facts.
struct RecipeRowView: View {
    var recipe: Recipe
    var fulfillment: RecipeFulfilment?

    /// Follows the text size (Dynamic Type), so the picture keeps its proportion to the text.
    @ScaledMetric(relativeTo: .headline) private var thumbnailSize: CGFloat = Sizes.recipeThumbnail

    var body: some View {
        HStack(spacing: Spacing.medium) {
            RecipeThumbnailView(pictureFileName: recipe.pictureFileName)
                .frame(width: thumbnailSize, height: thumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: Sizes.recipeThumbnailCornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)
                RecipeFulfilmentLabel(fulfillment: fulfillment)
                    .font(.subheadline)
                RecipeInfoLine(recipe: recipe, fulfillment: fulfillment)
            }
        }
        .padding(.vertical, Spacing.xxSmall)
    }
}

#Preview(traits: .previewData) {
    List {
        RecipeRowView(
            recipe: Recipe(id: 1, name: "Pasta Carbonara"),
            fulfillment: RecipeFulfilment(recipeID: 1, needFulfilled: true, calories: 640, dueScore: 10)
        )
        RecipeRowView(
            recipe: Recipe(id: 2, name: "Vegetable Stir Fry"),
            fulfillment: RecipeFulfilment(recipeID: 2, needFulfilledWithShoppingList: true, missingProductsCount: 5)
        )
        RecipeRowView(recipe: Recipe(id: 3, name: "Chocolate Cake"), fulfillment: RecipeFulfilment(recipeID: 3, missingProductsCount: 3))
    }
}
