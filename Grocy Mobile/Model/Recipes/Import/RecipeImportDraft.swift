//
//  RecipeImportDraft.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 14.11.26.
//

import Foundation

// MARK: - Draft

/// A recipe from a website, prepared to be saved as a Grocy recipe.
/// The person reviews and corrects it in `RecipeImportView` before it is saved.
struct RecipeImportDraft {
    var name: String
    var baseServings: Double
    var preparationHTML: String
    var steps: [RecipePreparationStep]
    var imageURL: URL?
    var importPicture: Bool
    var sourceURL: URL?
    var ingredients: [ImportedIngredient]

    /// Ingredients that will be saved: included, linked to a product and not saved yet.
    var ingredientsToSave: [ImportedIngredient] {
        ingredients.filter { $0.isIncluded && $0.productID != nil && !$0.isSaved }
    }

    /// Included ingredients without a product. Grocy needs a product for every ingredient, so they can't be saved.
    var ingredientsWithoutProduct: [ImportedIngredient] {
        ingredients.filter { $0.isIncluded && $0.productID == nil }
    }

    /// Included ingredients whose product or unit was only suggested, so the person should check them.
    var ingredientsToCheck: [ImportedIngredient] {
        ingredients.filter { $0.isIncluded && !$0.isSaved && $0.productID != nil && ($0.productMatch == .suggested || $0.unitMatch == .suggested || $0.hasUnmatchedUnit) }
    }
}

/// One ingredient of an imported recipe, with the amount in the unit the website uses.
struct ImportedIngredient: Identifiable, Hashable {
    let id = UUID()
    let line: ParsedIngredientLine

    var isIncluded: Bool = true
    var productID: Int?
    /// The amount in the unit `quID`, as shown to the person. It is converted to the product's stock unit when saving.
    var amount: Double
    var quID: Int?
    var note: String
    var ingredientGroup: String
    var variableAmount: String
    var onlyCheckSingleUnitInStock: Bool
    /// `true` once the ingredient was saved to the server.
    var isSaved: Bool = false
    /// How the product was found.
    var productMatch: IngredientMatchQuality = .none
    /// How the unit was found. `.none` when the line has a unit that no Grocy quantity unit matches.
    var unitMatch: IngredientMatchQuality = .none
    /// The name and plural name to suggest when the person creates a quantity unit for the line's unit.
    var newUnitName: String = ""
    var newUnitNamePlural: String = ""

    /// `true` when the website names a unit ("1 Bund") that no Grocy quantity unit matches.
    var hasUnmatchedUnit: Bool {
        line.unit != nil && unitMatch == .none
    }

    static func == (lhs: ImportedIngredient, rhs: ImportedIngredient) -> Bool {
        lhs.id == rhs.id && lhs.isIncluded == rhs.isIncluded && lhs.productID == rhs.productID && lhs.amount == rhs.amount
            && lhs.quID == rhs.quID && lhs.note == rhs.note && lhs.ingredientGroup == rhs.ingredientGroup
            && lhs.variableAmount == rhs.variableAmount && lhs.onlyCheckSingleUnitInStock == rhs.onlyCheckSingleUnitInStock
            && lhs.isSaved == rhs.isSaved && lhs.productMatch == rhs.productMatch && lhs.unitMatch == rhs.unitMatch
            && lhs.newUnitName == rhs.newUnitName && lhs.newUnitNamePlural == rhs.newUnitNamePlural
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Mapping

/// Maps a recipe parsed from a website to Grocy's products and quantity units.
struct RecipeImportMapper {
    let products: MDProducts
    let quantityUnits: MDQuantityUnits
    let conversions: MDQuantityUnitConversions

    /// Creates a draft from a parsed website recipe, with products and units matched as well as possible.
    func draft(from recipe: JSONParsedRecipe) -> RecipeImportDraft {
        let lines = recipe.recipeIngredient.map { IngredientLineParser.parse($0) }
        let unitLanguage = IngredientUnitLanguage.detect(in: lines) ?? .appLanguage
        let steps = RecipePreparationFormat.steps(from: recipe.recipeInstructions)
        let html = RecipePreparationFormat.html(introduction: recipe.schemaDescription, steps: steps, sourceURL: recipe.url)

        return RecipeImportDraft(
            name: recipe.name.strippingHTML.collapsingWhitespace,
            baseServings: Self.servings(from: recipe.recipeYield) ?? 1.0,
            preparationHTML: html,
            steps: steps,
            imageURL: recipe.image,
            importPicture: recipe.image != nil,
            sourceURL: recipe.url,
            ingredients: lines.map { ingredient(from: $0, unitLanguage: unitLanguage) }
        )
    }

    /// Creates an ingredient from a parsed line, with the matching product and quantity unit.
    func ingredient(from line: ParsedIngredientLine, unitLanguage: IngredientUnitLanguage = .appLanguage) -> ImportedIngredient {
        let productMatch = productCandidates(for: line.name, note: line.note).first
        let newUnitNames = line.newQuantityUnitNames(language: unitLanguage)
        var ingredient = ImportedIngredient(
            line: line,
            productID: productMatch?.product.id,
            amount: line.amount ?? 1.0,
            quID: nil,
            note: line.note,
            ingredientGroup: "",
            variableAmount: "",
            onlyCheckSingleUnitInStock: false,
            productMatch: productMatch?.quality ?? .none,
            newUnitName: newUnitNames?.singular ?? "",
            newUnitNamePlural: newUnitNames?.plural ?? ""
        )
        resetUnit(of: &ingredient)
        return ingredient
    }

    /// Sets the unit again after the product of an ingredient changed, as units depend on the product's conversions.
    func productChanged(_ ingredient: inout ImportedIngredient) {
        resetUnit(of: &ingredient)
    }

    /// Applies Grocy's unit rules again after the person chose another unit.
    func unitChanged(_ ingredient: inout ImportedIngredient) {
        ingredient.onlyCheckSingleUnitInStock = false
        ingredient.variableAmount = rangeText(of: ingredient.line)
        applyUnitRules(to: &ingredient, product: products.first(where: { $0.id == ingredient.productID }), unmatchedUnit: nil)
    }

    /// Fills in products and units that were missing, e.g. after the person created a product or quantity unit.
    /// Choices of the person and existing matches stay as they are.
    func fillMissingMatches(in draft: inout RecipeImportDraft) {
        for index in draft.ingredients.indices where !draft.ingredients[index].isSaved {
            var ingredient = draft.ingredients[index]
            var changed = false
            if ingredient.productID == nil, ingredient.productMatch == .none, let match = productCandidates(for: ingredient.line.name, note: ingredient.line.note).first {
                ingredient.productID = match.product.id
                ingredient.productMatch = match.quality
                changed = true
            }
            if ingredient.hasUnmatchedUnit, let unit = ingredient.line.unit, quantityUnitMatch(for: unit, knownUnit: ingredient.line.knownUnit) != nil {
                changed = true
            }
            if changed {
                resetUnit(of: &ingredient)
                draft.ingredients[index] = ingredient
            }
        }
    }

    private func resetUnit(of ingredient: inout ImportedIngredient) {
        let line = ingredient.line
        let match = line.unit.flatMap { quantityUnitMatch(for: $0, knownUnit: line.knownUnit) }
        ingredient.quID = match?.unit.id
        ingredient.unitMatch = match?.quality ?? .none
        ingredient.onlyCheckSingleUnitInStock = false
        ingredient.variableAmount = rangeText(of: line)
        applyUnitRules(to: &ingredient, product: products.first(where: { $0.id == ingredient.productID }), unmatchedUnit: match == nil ? line.unit : nil)
    }

    /// A range like "2-3" can't be stored as an amount, so it's shown as written.
    private func rangeText(of line: ParsedIngredientLine) -> String {
        line.amountText.map { [$0, line.unit].compactMap { $0 }.joined(separator: " ") } ?? ""
    }

    /// Makes the unit valid for Grocy:
    /// - Without a unit (e.g. "3 eggs"), the product's consume unit is used.
    /// - When the unit can't be converted to the product's stock unit (e.g. "1 pinch of salt"),
    ///   only "any amount in stock" can be checked, and the amount is shown as written on the website.
    private func applyUnitRules(to ingredient: inout ImportedIngredient, product: MDProduct?, unmatchedUnit: String?) {
        guard let product else { return }

        if ingredient.quID == nil, unmatchedUnit == nil {
            ingredient.quID = product.quIDConsume
        }

        let isConvertible = ingredient.quID.map { stockAmount(for: ingredient.amount, quID: $0, product: product) != nil } ?? false
        let hasNoAmount = ingredient.line.amount == nil
        if !isConvertible || hasNoAmount {
            ingredient.onlyCheckSingleUnitInStock = true
            if ingredient.quID == nil {
                ingredient.quID = product.quIDConsume
            }
            if ingredient.variableAmount.isEmpty, let unmatchedUnit {
                let amountText = ingredient.line.amountText ?? ingredient.line.amount?.formattedAmount
                ingredient.variableAmount = [amountText, unmatchedUnit].compactMap { $0 }.joined(separator: " ")
            }
        }
    }

    // MARK: Names

    /// Lowercased, without diacritics, plural markers and punctuation, for comparing names.
    static func normalizedName(_ name: String) -> String {
        name.removingPluralMarker
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .replacingOccurrences(of: "ß", with: "ss")
            .replacingOccurrences(of: "[^\\p{L}\\p{N} ]", with: " ", options: .regularExpression)
            .split(separator: " ")
            .map { String($0).removingPluralMarker }
            .joined(separator: " ")
    }

    // MARK: Conversion

    /// Whether the ingredient's unit can't be converted to the product's stock unit yet,
    /// so a product-specific conversion would let Grocy check the amount in stock.
    func needsUnitConnection(_ ingredient: ImportedIngredient, product: MDProduct) -> Bool {
        guard let quID = ingredient.quID, quID != product.quIDStock, !ingredient.hasUnmatchedUnit else { return false }
        return stockAmount(for: 1, quID: quID, product: product) == nil
    }

    /// Converts an amount in the unit `quID` to the product's stock unit, the way Grocy stores ingredient amounts.
    /// Returns `nil` when there's no conversion between the two units.
    func stockAmount(for amount: Double, quID: Int, product: MDProduct) -> Double? {
        Self.stockAmount(for: amount, quID: quID, product: product, conversions: conversions)
    }

    static func stockAmount(for amount: Double, quID: Int, product: MDProduct, conversions: MDQuantityUnitConversions) -> Double? {
        RecipeAmountConversion.stockAmount(for: amount, quID: quID, product: product, conversions: conversions)
    }

    // MARK: Servings

    /// The number of servings from a yield like "4", "4 Portionen", "Serves 4-6" or "12 cookies".
    static func servings(from yield: String?) -> Double? {
        guard let yield else { return nil }
        let pattern = #"(\d+(?:[.,]\d+)?)"#
        guard let range = yield.range(of: pattern, options: .regularExpression) else { return nil }
        let value = Double(yield[range].replacingOccurrences(of: ",", with: "."))
        return (value ?? 0) > 0 ? value : nil
    }
}
