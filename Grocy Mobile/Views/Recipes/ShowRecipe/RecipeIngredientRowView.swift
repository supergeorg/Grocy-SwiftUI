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
    var quantityUnit: MDQuantityUnit?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5.0) {
                if !recipePos.recipeVariableAmount.isEmpty {
                    Text(recipePos.recipeVariableAmount)
                        .font(.title2)
                } else {
                    Text("\(recipePos.recipeAmount.formattedAmount) \(quantityUnit?.getName(amount: recipePos.recipeAmount) ?? "") \(recipePos.productName)")
                        .font(.title2)
                }
                if recipePos.missingAmount == 0.0 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(Text("Enough in stock")) (\(recipePos.stockAmount.formattedAmount) \(quantityUnit?.getName(amount: recipePos.stockAmount) ?? ""))")
                            .italic()
                            .font(.caption)
                    }
                } else {
                    HStack {
                        if recipePos.amountOnShoppingList > 0.0 {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.yellow)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                        Text("Not enough in stock, \(recipePos.missingAmount.formattedAmount) missing, \(recipePos.amountOnShoppingList.formattedAmount) already on shopping list")
                            .italic()
                            .font(.caption)
                    }
                }
                if !recipePos.recipeVariableAmount.isEmpty {
                    Text("Variable amount")
                        .italic()
                        .font(.caption2)
                }
                if recipePos.note.isEmpty == false {
                    Text(recipePos.note)
                        .font(.caption)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(recipePos.calories.formattedAmount) kcal")
                    .font(.caption)
                if recipePos.costs >= 0.01 {
                    Text(grocyVM.getFormattedCurrency(amount: recipePos.costs))
                        .font(.caption)
                }
            }
        }
    }
}

#Preview {
    List {
        RecipeIngredientRowView(recipePos: RecipePosResolvedElement(quID: 1, productName: "Product name"), quantityUnit: MDQuantityUnit(name: "QU"))
        RecipeIngredientRowView(recipePos: RecipePosResolvedElement(missingAmount: 1.0, quID: 2, productName: "Product name missing"), quantityUnit: MDQuantityUnit(name: "QU"))
        RecipeIngredientRowView(recipePos: RecipePosResolvedElement(missingAmount: 1.0, amountOnShoppingList: 1.0, quID: 2, productName: "Product name shopping list"), quantityUnit: MDQuantityUnit(name: "QU"))
    }
}
