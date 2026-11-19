//
//  MealPlanLookup.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import Foundation

/// Everything the meal plan's rows look up (recipes, their fulfillment, products, stock), indexed once per update
/// instead of searched for every row.
struct MealPlanLookup {
    let recipesByID: [Int: Recipe]
    let fulfillmentsByRecipeID: [Int: RecipeFulfilment]
    let productsByID: [Int: MDProduct]
    let quantityUnitsByID: [Int: MDQuantityUnit]
    let stockAmountsByProductID: [Int: Double]
    let sectionsByID: [Int: MDMealPlanSection]
    /// The internal recipes (day, week, shadow), by name.
    private let internalRecipeIDs: [String: Int]

    let showsStock: Bool
    let showsCosts: Bool
    let energyUnit: String

    init(
        recipes: Recipes,
        fulfillments: RecipeFulfilments,
        products: MDProducts,
        quantityUnits: MDQuantityUnits,
        stock: [StockElement],
        sections: MDMealPlanSections,
        systemConfig: SystemConfig?
    ) {
        self.recipesByID = Dictionary(recipes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.internalRecipeIDs = Dictionary(
            recipes.filter { $0.type != .normal }.map { ($0.name, $0.id) },
            uniquingKeysWith: { first, _ in first }
        )
        self.fulfillmentsByRecipeID = Dictionary(fulfillments.map { ($0.recipeID, $0) }, uniquingKeysWith: { first, _ in first })
        self.productsByID = Dictionary(products.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.quantityUnitsByID = Dictionary(quantityUnits.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.stockAmountsByProductID = Dictionary(stock.map { ($0.productID, $0.amountAggregated) }, uniquingKeysWith: { first, _ in first })
        self.sectionsByID = Dictionary(sections.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.showsStock = systemConfig?.featureFlagStock ?? true
        self.showsCosts = systemConfig?.featureFlagStockPriceTracking ?? true
        self.energyUnit = systemConfig?.energyUnit ?? "kcal"
    }

    // MARK: - Recipes

    func recipe(of entry: MealPlanEntry) -> Recipe? {
        entry.recipeID.flatMap { recipesByID[$0] }
    }

    /// The internal recipe Grocy keeps for a recipe entry, with the entry's servings.
    func shadowRecipeID(of entry: MealPlanEntry) -> Int? {
        guard entry.type == .recipe else { return nil }
        return internalRecipeIDs[MealPlanNames.shadowRecipeName(day: entry.day, entryID: entry.id)]
    }

    func fulfillment(of entry: MealPlanEntry) -> RecipeFulfilment? {
        shadowRecipeID(of: entry).flatMap { fulfillmentsByRecipeID[$0] }
    }

    /// Costs and calories of everything planned on a day.
    func dayFulfillment(for day: Date) -> RecipeFulfilment? {
        dayRecipeID(for: day).flatMap { fulfillmentsByRecipeID[$0] }
    }

    /// Grocy's recipe of a day, which sums up everything planned on it.
    func dayRecipeID(for day: Date) -> Int? {
        internalRecipeIDs[MealPlanNames.dayName(for: day)]
    }

    /// Grocy's week recipes for the given days. They count weeks from Monday, so a week that starts on another day
    /// lies in two of them.
    func weekRecipeIDs(for days: [Date]) -> [Int] {
        var ids: [Int] = []
        for day in days {
            if let id = internalRecipeIDs[MealPlanNames.weekName(for: day)], !ids.contains(id) {
                ids.append(id)
            }
        }
        return ids
    }

    // MARK: - Products

    func product(of entry: MealPlanEntry) -> MDProduct? {
        entry.productID.flatMap { productsByID[$0] }
    }

    /// The unit the entry's amount is in: the product's stock unit.
    func quantityUnit(of entry: MealPlanEntry) -> MDQuantityUnit? {
        guard let product = product(of: entry) else { return nil }
        return quantityUnitsByID[product.quIDStock]
    }

    func isInStock(_ entry: MealPlanEntry) -> Bool {
        guard let productID = entry.productID else { return false }
        return (stockAmountsByProductID[productID] ?? 0) >= entry.productAmount
    }

    // MARK: - Sections

    func section(of entry: MealPlanEntry) -> MDMealPlanSection? {
        sectionsByID[entry.sectionID]
    }

    /// For sorting a day's entries like the sections.
    func sortKey(of entry: MealPlanEntry) -> (Int, Int) {
        (section(of: entry)?.sortNumber ?? Int.max, entry.id)
    }
}
