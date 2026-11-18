//
//  RecipeIngredientRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 09.01.26.
//

import SwiftUI

struct RecipeIngredientRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var recipePos: RecipePosResolvedElement
    /// The amount needed, in `quantityUnit` (the ingredient's own unit when it can be converted, else the stock unit).
    var amount: Double
    var quantityUnit: MDQuantityUnit?
    /// The product's stock unit, which the stock and missing amounts are in.
    var stockQuantityUnit: MDQuantityUnit?
    /// The included recipe this ingredient comes from, if it isn't one of the recipe's own.
    var nestedRecipeName: String? = nil

    private enum Status {
        case fulfilled, onShoppingList, missing
    }

    private var status: Status {
        if recipePos.missingAmount == 0.0 { return .fulfilled }
        return recipePos.amountOnShoppingList > 0.0 ? .onShoppingList : .missing
    }

    private var statusSymbol: String {
        switch status {
        case .fulfilled: MySymbols.fulfilled
        case .onShoppingList: MySymbols.partiallyFulfilled
        case .missing: MySymbols.notFulfilled
        }
    }

    private var statusColor: Color {
        switch status {
        case .fulfilled: Color(.GrocyColors.grocyGreen)
        case .onShoppingList: Color(.GrocyColors.grocyYellow)
        case .missing: Color(.GrocyColors.grocyRed)
        }
    }

    private var amountText: String {
        if !recipePos.recipeVariableAmount.isEmpty {
            return recipePos.recipeVariableAmount
        }
        let unitName = quantityUnit?.getName(amount: amount) ?? ""
        return unitName.isEmpty ? amount.formattedAmount : "\(amount.formattedAmount) \(unitName)"
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
            // The status is also written out below, so the symbol is decorative for VoiceOver.
            Image(systemName: statusSymbol)
                .foregroundStyle(statusColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("\(Text(amountText).fontWeight(.semibold)) \(recipePos.productName)")

                Group {
                    switch status {
                    case .fulfilled:
                        Text(
                            "\(Text("Enough in stock")) (\(recipePos.stockAmount.formattedAmount) \(stockQuantityUnit?.getName(amount: recipePos.stockAmount) ?? ""))"
                        )
                    case .onShoppingList, .missing:
                        Text(
                            "Not enough in stock, \(recipePos.missingAmount.formattedAmount) missing, \(recipePos.amountOnShoppingList.formattedAmount) already on shopping list"
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !recipePos.recipeVariableAmount.isEmpty {
                    Text("Variable amount")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !recipePos.note.isEmpty {
                    Text(recipePos.note)
                        .font(.subheadline)
                }
                if let nestedRecipeName {
                    // An HStack instead of a Label: in a List row, a Label gets the wide icon column of the row.
                    HStack(spacing: Spacing.xxSmall) {
                        Image(systemName: MySymbols.nestedRecipe)
                        Text(nestedRecipeName)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: Spacing.small)

            VStack(alignment: .trailing, spacing: Spacing.xxSmall) {
                if recipePos.calories > 0 {
                    Text("\(recipePos.calories.formattedAmount) kcal")
                }
                if recipePos.costs >= 0.01 {
                    Text(grocyVM.getFormattedCurrency(amount: recipePos.costs))
                }
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .previewData) {
    List {
        RecipeIngredientRowView(
            recipePos: RecipePosResolvedElement(quID: 1, calories: 120, productName: "Product name"),
            amount: 1,
            quantityUnit: MDQuantityUnit(name: "QU")
        )
        RecipeIngredientRowView(
            recipePos: RecipePosResolvedElement(missingAmount: 1.0, quID: 2, note: "Finely chopped", productName: "Product name missing"),
            amount: 2,
            quantityUnit: MDQuantityUnit(name: "QU"),
            nestedRecipeName: "Pizza dough"
        )
        RecipeIngredientRowView(
            recipePos: RecipePosResolvedElement(
                missingAmount: 1.0,
                amountOnShoppingList: 1.0,
                quID: 2,
                recipeVariableAmount: "A pinch",
                productName: "Product name shopping list"
            ),
            amount: 1,
            quantityUnit: MDQuantityUnit(name: "QU")
        )
    }
}
