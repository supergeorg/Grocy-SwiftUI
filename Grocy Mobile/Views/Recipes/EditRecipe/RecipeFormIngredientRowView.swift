//
//  RecipePosRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 02.02.26.
//

import SwiftUI

struct RecipeFormIngredientRowView: View {
    var recipePos: RecipePos

    var product: MDProduct?
    var quantityUnit: MDQuantityUnit?
    var quantityUnitConversions: MDQuantityUnitConversions = []

    /// Grocy stores the amount in the product's stock unit, so it's converted to the ingredient's unit for showing it.
    private var amount: Double {
        RecipeAmountConversion.displayAmount(
            forStored: recipePos.amount,
            quID: recipePos.quID,
            onlyCheckSingleUnitInStock: recipePos.onlyCheckSingleUnitInStock,
            product: product,
            conversions: quantityUnitConversions
        )
    }

    var body: some View {
        HStack {
            Text(product?.name ?? "")
            Spacer()
            Text("\(amount.formattedAmount) \(quantityUnit?.getName(amount: amount) ?? "")")
        }
    }
}
