//
//  RecipeImportIngredientRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 14.11.26.
//

import SwiftUI

/// One ingredient of a recipe import: the line from the website, and how it will be saved.
/// Suggested matches and missing units are named in text, not only by their symbol or color.
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
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(ingredient.line.originalText)
                .strikethrough(!ingredient.isIncluded)
                .foregroundStyle(ingredient.isIncluded ? .primary : .secondary)

            Group {
                if ingredient.isSaved {
                    Label("Saved", systemImage: MySymbols.success)
                } else if !ingredient.isIncluded {
                    Label("Not imported", systemImage: MySymbols.notImported)
                } else if let product {
                    if ingredient.productMatch == .suggested {
                        Label {
                            Text("Suggested: \(amountText) \(product.name)")
                        } icon: {
                            Image(systemName: MySymbols.suggestedMatch)
                                .foregroundStyle(.tint)
                        }
                    } else {
                        Label("\(amountText) \(product.name)", systemImage: MySymbols.product)
                    }
                    if ingredient.hasUnmatchedUnit, let unit = ingredient.line.unit {
                        Label {
                            Text("Unit “\(unit)” not found")
                        } icon: {
                            Image(systemName: MySymbols.warning)
                                .foregroundStyle(Color(.GrocyColors.grocyYellow))
                        }
                    } else if ingredient.unitMatch == .suggested, let unit = ingredient.line.unit, let quantityUnit {
                        Label {
                            Text("Unit “\(unit)” suggested as “\(quantityUnit.name)”")
                        } icon: {
                            Image(systemName: MySymbols.suggestedMatch)
                                .foregroundStyle(.tint)
                        }
                    }
                } else {
                    Label {
                        Text("No product selected")
                    } icon: {
                        Image(systemName: MySymbols.warning)
                            .foregroundStyle(Color(.GrocyColors.grocyYellow))
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .previewData) {
    let line = IngredientLineParser.parse("200 g Butter, weich")
    List {
        RecipeImportIngredientRowView(
            ingredient: ImportedIngredient(line: line, productID: 1, amount: 200, quID: 1, note: line.note, ingredientGroup: "", variableAmount: "", onlyCheckSingleUnitInStock: false, productMatch: .exact, unitMatch: .exact),
            product: MDProduct(name: "Butter"),
            quantityUnit: MDQuantityUnit(name: "g")
        )
        RecipeImportIngredientRowView(
            ingredient: ImportedIngredient(line: IngredientLineParser.parse("125 ml süße Sahne"), productID: 2, amount: 125, quID: 2, note: "", ingredientGroup: "", variableAmount: "", onlyCheckSingleUnitInStock: false, productMatch: .suggested, unitMatch: .exact),
            product: MDProduct(name: "Sahne"),
            quantityUnit: MDQuantityUnit(name: "Milliliter")
        )
        RecipeImportIngredientRowView(
            ingredient: ImportedIngredient(line: IngredientLineParser.parse("1 Bund Petersilie"), productID: 3, amount: 1, quID: 3, note: "", ingredientGroup: "", variableAmount: "1 Bund", onlyCheckSingleUnitInStock: true, productMatch: .exact),
            product: MDProduct(name: "Petersilie"),
            quantityUnit: MDQuantityUnit(name: "Stück")
        )
        RecipeImportIngredientRowView(
            ingredient: ImportedIngredient(line: IngredientLineParser.parse("1 Prise Muskat"), amount: 1, note: "", ingredientGroup: "", variableAmount: "", onlyCheckSingleUnitInStock: false)
        )
    }
}
