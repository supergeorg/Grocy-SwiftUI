//
//  RecipeCardView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// A recipe in the gallery layout of the recipe overview: a large picture, the name, the stock status as subtitle and a few facts.
/// Like a photo gallery, the text sits on the page below the picture, without a card around it, so cards with more text don't look uneven.
/// Content layer, so no glass (Liquid Glass belongs to the navigation layer).
struct RecipeCardView: View {
    var recipe: Recipe
    var fulfillment: RecipeFulfilment?

    private var pictureShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Sizes.recipeCardCornerRadius, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Color.clear
                .aspectRatio(Sizes.recipeCardPictureRatio, contentMode: .fit)
                .overlay {
                    RecipeThumbnailView(pictureFileName: recipe.pictureFileName)
                }
                .clipShape(pictureShape)

            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                RecipeFulfilmentLabel(fulfillment: fulfillment, compact: true)
                    .font(.subheadline)
                RecipeInfoLine(recipe: recipe, fulfillment: fulfillment)
            }
            .padding(.horizontal, Spacing.xxSmall)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentShape(.rect)
        #if os(iOS)
            .contentShape(.hoverEffect, pictureShape)
        #endif
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .previewData) {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
            RecipeCardView(
                recipe: Recipe(id: 1, name: "Pasta Carbonara"),
                fulfillment: RecipeFulfilment(recipeID: 1, needFulfilled: true, calories: 640, dueScore: 10)
            )
            RecipeCardView(
                recipe: Recipe(id: 2, name: "Vegetable Stir Fry with a long name"),
                fulfillment: RecipeFulfilment(recipeID: 2, needFulfilledWithShoppingList: true, missingProductsCount: 5)
            )
            RecipeCardView(recipe: Recipe(id: 3, name: "Chocolate Cake"), fulfillment: RecipeFulfilment(recipeID: 3, missingProductsCount: 3))
        }
        .padding()
    }
}
