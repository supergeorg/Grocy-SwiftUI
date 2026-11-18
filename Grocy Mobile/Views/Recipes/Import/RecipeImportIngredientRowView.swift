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
    /// `true` while Apple Intelligence looks for this ingredient's product.
    var isMatching: Bool = false

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

            VStack(alignment: .leading, spacing: Spacing.hairline) {
                if ingredient.isSaved {
                    Label("Saved", systemImage: MySymbols.success)
                        .foregroundStyle(.secondary)
                } else if !ingredient.isIncluded {
                    Label("Not imported", systemImage: MySymbols.notImported)
                        .foregroundStyle(.secondary)
                } else if isMatching {
                    Label {
                        Text("Looking for a product…")
                            .foregroundStyle(.secondary)
                    } icon: {
                        AppleIntelligenceSymbol(isActive: true)
                    }
                } else if let product {
                    // The product is what gets saved, so it's as readable as the line; the symbol tells how sure the match is.
                    if ingredient.productMatch == .intelligence {
                        Label {
                            Text("Apple Intelligence: \(amountText) \(product.name)")
                        } icon: {
                            AppleIntelligenceSymbol()
                        }
                    } else if ingredient.productMatch == .suggested {
                        Label {
                            Text("Suggested: \(amountText) \(product.name)")
                        } icon: {
                            Image(systemName: MySymbols.suggestedMatch)
                                .foregroundStyle(.tint)
                        }
                    } else {
                        Label {
                            Text("\(amountText) \(product.name)")
                        } icon: {
                            Image(systemName: MySymbols.confirmedMatch)
                                .foregroundStyle(Color(.GrocyColors.grocyGreen))
                        }
                    }
                    if ingredient.hasUnmatchedUnit, let unit = ingredient.line.unit {
                        Label {
                            Text("Unit “\(unit)” not found")
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: MySymbols.warning)
                                .foregroundStyle(Color(.GrocyColors.grocyYellow))
                        }
                        .font(.caption)
                    } else if ingredient.unitMatch == .suggested, let unit = ingredient.line.unit, let quantityUnit {
                        Label {
                            Text("Unit “\(unit)” suggested as “\(quantityUnit.name)”")
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: MySymbols.suggestedMatch)
                                .foregroundStyle(.tint)
                        }
                        .font(.caption)
                    }
                } else {
                    // Without a product, the ingredient isn't imported.
                    Label("No product selected", systemImage: MySymbols.missingProduct)
                        .foregroundStyle(Color(.GrocyColors.grocyRed))
                }
            }
            .font(.subheadline)
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
