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

    static func == (lhs: ImportedIngredient, rhs: ImportedIngredient) -> Bool {
        lhs.id == rhs.id && lhs.isIncluded == rhs.isIncluded && lhs.productID == rhs.productID && lhs.amount == rhs.amount
            && lhs.quID == rhs.quID && lhs.note == rhs.note && lhs.ingredientGroup == rhs.ingredientGroup
            && lhs.variableAmount == rhs.variableAmount && lhs.onlyCheckSingleUnitInStock == rhs.onlyCheckSingleUnitInStock
            && lhs.isSaved == rhs.isSaved
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
            ingredients: recipe.recipeIngredient.map { ingredient(from: IngredientLineParser.parse($0)) }
        )
    }

    /// Creates an ingredient from a parsed line, with the matching product and quantity unit.
    func ingredient(from line: ParsedIngredientLine) -> ImportedIngredient {
        var ingredient = ImportedIngredient(
            line: line,
            productID: matchProduct(for: line.name)?.id,
            amount: line.amount ?? 1.0,
            quID: nil,
            note: line.note,
            ingredientGroup: "",
            variableAmount: "",
            onlyCheckSingleUnitInStock: false
        )
        resetUnit(of: &ingredient)
        return ingredient
    }

    /// Sets the unit again after the product of an ingredient changed, as units depend on the product's conversions.
    func productChanged(_ ingredient: inout ImportedIngredient) {
        resetUnit(of: &ingredient)
    }

    private func resetUnit(of ingredient: inout ImportedIngredient) {
        let line = ingredient.line
        let unit = line.unit.flatMap { matchQuantityUnit(for: $0, knownUnit: line.knownUnit) }
        ingredient.quID = unit?.id
        ingredient.onlyCheckSingleUnitInStock = false
        // A range like "2-3" can't be stored as an amount, so it's shown as written
        ingredient.variableAmount = line.amountText.map { [$0, line.unit].compactMap { $0 }.joined(separator: " ") } ?? ""
        applyUnitRules(to: &ingredient, product: products.first(where: { $0.id == ingredient.productID }), unmatchedUnit: unit == nil ? line.unit : nil)
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

    // MARK: Products

    /// Finds the product for an ingredient name: an exact name match first,
    /// then the longest product name that appears as a whole word in the ingredient ("Butter" in "kalte Butter").
    func matchProduct(for ingredientName: String) -> MDProduct? {
        let name = Self.normalizedName(ingredientName)
        guard !name.isEmpty else { return nil }
        let activeProducts = products.filter(\.active)
        let normalizedProducts = activeProducts.map { (product: $0, name: Self.normalizedName($0.name)) }.filter { !$0.name.isEmpty }

        if let exact = normalizedProducts.first(where: { $0.name == name || Self.singular($0.name) == Self.singular(name) }) {
            return exact.product
        }

        let ingredientWords = Set(name.split(separator: " ").map { Self.singular(String($0)) })
        let containedProducts = normalizedProducts.filter { candidate in
            let productWords = candidate.name.split(separator: " ").map { Self.singular(String($0)) }
            return !productWords.isEmpty && productWords.allSatisfy { ingredientWords.contains($0) }
        }
        if let best = containedProducts.max(by: { $0.name.count < $1.name.count }) {
            return best.product
        }

        // Compound words ("Schlagsahne" contains "Sahne"), only for product names that aren't too short
        let compounds = normalizedProducts.filter { $0.name.count >= 4 && !$0.name.contains(" ") && name.replacingOccurrences(of: " ", with: "").hasSuffix($0.name) }
        return compounds.max(by: { $0.name.count < $1.name.count })?.product
    }

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

    /// A simple singular form for English and German words ("tomatoes" → "tomato", "Zwiebeln" → "zwiebel").
    static func singular(_ word: String) -> String {
        let irregular = ["eier": "ei", "leaves": "leaf", "knives": "knife", "loaves": "loaf"]
        if let singular = irregular[word] { return singular }
        guard word.count > 3 else { return word }
        for suffix in ["oes", "ies", "es", "en", "n", "s", "e"] where word.hasSuffix(suffix) {
            let stem = String(word.dropLast(suffix.count))
            if stem.count >= 3 { return suffix == "ies" ? stem + "y" : stem }
        }
        return word
    }

    // MARK: Quantity units

    /// Finds the Grocy quantity unit for a unit from a website, by its name or plural name,
    /// or by any spelling of the same known unit (so "EL" finds a unit named "Esslöffel" or "Tablespoon").
    func matchQuantityUnit(for unit: String, knownUnit: KnownIngredientUnit?) -> MDQuantityUnit? {
        let token = unit.normalizedUnitToken
        let activeUnits = quantityUnits.filter(\.active)
        let spellings = Set([token] + (knownUnit?.aliases ?? []))

        if let direct = activeUnits.first(where: { $0.name.normalizedUnitToken == token || $0.namePlural.normalizedUnitToken == token }) {
            return direct
        }
        return activeUnits.first { quantityUnit in
            spellings.contains(quantityUnit.name.normalizedUnitToken) || spellings.contains(quantityUnit.namePlural.normalizedUnitToken)
        }
    }

    // MARK: Conversion

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
