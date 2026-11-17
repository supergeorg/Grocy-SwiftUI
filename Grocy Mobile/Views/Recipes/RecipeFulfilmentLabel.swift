//
//  RecipeFulfilmentLabel.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// Whether the recipe's ingredients are in stock, as a short subtitle for the recipe list and gallery.
struct RecipeFulfilmentLabel: View {
    var fulfillment: RecipeFulfilment?
    /// Only "Enough in stock" or "Not enough in stock"; the symbol's color tells whether the missing ingredients are on the shopping list.
    var compact: Bool = false

    var body: some View {
        if let fulfillment {
            if fulfillment.needFulfilled {
                label("Enough in stock", symbol: MySymbols.fulfilled, color: Color(.GrocyColors.grocyGreen))
            } else if compact {
                label("Not enough in stock", symbol: fulfillment.needFulfilledWithShoppingList ? MySymbols.partiallyFulfilled : MySymbols.notFulfilled, color: Color(fulfillment.needFulfilledWithShoppingList ? .GrocyColors.grocyYellow : .GrocyColors.grocyRed))
            } else if fulfillment.needFulfilledWithShoppingList {
                label("Not enough in stock, but already on the shopping list", symbol: MySymbols.partiallyFulfilled, color: Color(.GrocyColors.grocyYellow))
            } else {
                label("Not enough in stock, \(fulfillment.missingProductsCount ?? 0) ingredient missing", symbol: MySymbols.notFulfilled, color: Color(.GrocyColors.grocyRed))
            }
        }
    }

    private func label(_ title: LocalizedStringKey, symbol: String, color: Color) -> some View {
        // An HStack instead of a Label: in a List row, a Label gets the wide icon column of the row.
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(title)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        RecipeFulfilmentLabel(fulfillment: RecipeFulfilment(recipeID: 1, needFulfilled: true))
        RecipeFulfilmentLabel(fulfillment: RecipeFulfilment(recipeID: 2, needFulfilledWithShoppingList: true, missingProductsCount: 2))
        RecipeFulfilmentLabel(fulfillment: RecipeFulfilment(recipeID: 3, missingProductsCount: 3))
    }
}
