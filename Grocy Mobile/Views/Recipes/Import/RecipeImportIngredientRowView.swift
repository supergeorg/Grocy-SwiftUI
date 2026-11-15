//
//  RecipeImportIngredientRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 14.11.26.
//

import SwiftUI

struct RecipeImportIngredientRowView: View {
    var ingredient: ImportedIngredient
    var product: MDProduct?
    var quantityUnit: MDQuantityUnit?

    private var amountText: String {
        if !ingredient.variableAmount.isEmpty {
            return ingredient.variableAmount
        }
        return "\(ingredient.amount.formattedAmount) \(quantityUnit?.getName(amount: ingredient.amount) ?? "")"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            Text(ingredient.line.originalText)
                .strikethrough(!ingredient.isIncluded)
                .foregroundStyle(ingredient.isIncluded ? .primary : .secondary)

            if !ingredient.isIncluded {
                Text("Not imported")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let product {
                Label {
                    Text("\(amountText) \(product.name)")
                } icon: {
                    Image(systemName: MySymbols.product)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                Label {
                    Text("No product selected")
                } icon: {
                    Image(systemName: MySymbols.warning)
                        .foregroundStyle(Color(.GrocyColors.grocyYellow))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .previewData) {
    let line = IngredientLineParser.parse("200 g Butter, weich")
    List {
        RecipeImportIngredientRowView(
            ingredient: ImportedIngredient(line: line, productID: 1, amount: 200, quID: 1, note: line.note, ingredientGroup: "", variableAmount: "", onlyCheckSingleUnitInStock: false),
            product: MDProduct(name: "Butter"),
            quantityUnit: MDQuantityUnit(name: "g")
        )
        RecipeImportIngredientRowView(
            ingredient: ImportedIngredient(line: IngredientLineParser.parse("1 Prise Muskat"), amount: 1, note: "", ingredientGroup: "", variableAmount: "", onlyCheckSingleUnitInStock: false)
        )
    }
}
