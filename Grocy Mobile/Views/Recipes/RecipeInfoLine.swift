//
//  RecipeInfoLine.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// Small facts about a recipe (servings, energy, costs per serving, due score) on one line, for the recipe list and gallery.
struct RecipeInfoLine: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var recipe: Recipe
    var fulfillment: RecipeFulfilment?

    var body: some View {
        // Wraps to the next line instead of truncating when the text is large (Dynamic Type) or the card narrow.
        FlowLayout(spacing: Spacing.small) {
            item(recipe.desiredServings.formattedAmount, symbol: MySymbols.servings, accessibilityTitle: "Servings")
            if let calories = fulfillment?.calories, calories > 0 {
                item("\(calories.formattedAmount) kcal", symbol: MySymbols.energy, accessibilityTitle: "Energy")
            }
            if let costsPerServing = fulfillment?.costsPerServing, costsPerServing >= 0.01 {
                item(grocyVM.getFormattedCurrency(amount: costsPerServing), symbol: MySymbols.price, accessibilityTitle: "per serving")
            }
            if let dueScore = fulfillment?.dueScore {
                item("\(dueScore)", symbol: MySymbols.due, accessibilityTitle: "Due score")
            }
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
    }

    private func item(_ value: String, symbol: String, accessibilityTitle: LocalizedStringKey) -> some View {
        // An HStack instead of a Label: in a List row, a Label gets the wide icon column of the row.
        HStack(spacing: Spacing.xxSmall) {
            Image(systemName: symbol)
            Text(value)
        }
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityTitle))
        .accessibilityValue(Text(value))
    }
}

#Preview(traits: .previewData) {
    RecipeInfoLine(
        recipe: Recipe(name: "Pasta", desiredServings: 2),
        fulfillment: RecipeFulfilment(recipeID: 1, costsPerServing: 2.5, calories: 650, dueScore: 12)
    )
}
