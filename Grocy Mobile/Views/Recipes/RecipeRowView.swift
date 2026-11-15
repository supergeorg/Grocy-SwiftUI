//
//  RecipeRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 02.12.22.
//

import SwiftUI

struct RecipeRowView: View {
    var recipe: Recipe
    /// Placeholder symbol size that still follows the text size (Dynamic Type).
    @ScaledMetric(relativeTo: .title) private var placeholderSymbolSize: CGFloat = 36
    var fulfillment: RecipeFulfilment?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)

            VStack(alignment: .center, spacing: 0) {
                // Top image section with name overlay
                ZStack(alignment: .bottom) {
                    Group {
                        if let pictureFileName = recipe.pictureFileName {
                            PictureView(pictureFileName: pictureFileName, pictureType: .recipePictures)
                                .scaledToFill()
                        } else {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.gray.opacity(0.15))
                                .overlay(
                                    Image(systemName: MySymbols.picturePlaceholder)
                                        .font(.system(size: placeholderSymbolSize))
                                        .foregroundStyle(.gray.opacity(0.6))
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                    // Bottom fade so text reads over image
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.6)]),
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .frame(height: Sizes.recipeTitleFadeHeight)
                    .clipped()

                    // Recipe name placed on the image
                    Text(recipe.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, Spacing.medium)
                        .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 2)
                }
                .clipped()

                HStack(alignment: .center, spacing: Spacing.small) {
                    VStack(alignment: .center, spacing: Spacing.xSmall) {
                        Text("\(fulfillment?.dueScore ?? 0)")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Due score")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(minWidth: Sizes.recipeScoreMinWidth)

                    Spacer()

                    if fulfillment?.needFulfilled == true {
                        VStack(alignment: .trailing) {
                            Image(systemName: MySymbols.fulfilled)
                                .foregroundStyle(Color(.GrocyColors.grocyGreen))
                                .font(.title)
                            Text("Enough in stock")
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else if fulfillment?.needFulfilledWithShoppingList == true {
                        VStack(alignment: .trailing) {
                            Image(systemName: MySymbols.partiallyFulfilled)
                                .foregroundStyle(Color(.GrocyColors.grocyYellow))
                                .font(.title)
                            Text("Not enough in stock, \(fulfillment?.missingProductsCount ?? 0) ingredient missing but already on the shopping list")
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)

                        }
                    } else {
                        VStack(alignment: .trailing) {
                            Image(systemName: MySymbols.notFulfilled)
                                .foregroundStyle(Color(.GrocyColors.grocyRed))
                                .font(.title)
                            Text("Not enough in stock, \(fulfillment?.missingProductsCount ?? 0) ingredient missing")
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
            }
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 4, y: 4)
    }
}

#Preview(traits: .previewData) {
    ScrollView {
        VStack {
            RecipeRowView(recipe: Recipe(id: 1, name: "Pasta Carbonara"), fulfillment: RecipeFulfilment(recipeID: 1, needFulfilled: true, dueScore: 10))
            RecipeRowView(recipe: Recipe(id: 2, name: "Vegetable Stir Fry"), fulfillment: RecipeFulfilment(recipeID: 2, needFulfilledWithShoppingList: true, missingProductsCount: 5))
            RecipeRowView(recipe: Recipe(id: 3, name: "Chocolate Cake"), fulfillment: RecipeFulfilment(recipeID: 3, missingProductsCount: 3))
        }
        .padding()
    }
}
