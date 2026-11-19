//
//  MealPlanModelTests.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import Foundation
import SwiftData
import Testing

@testable import Grocy_Mobile

@MainActor
@Suite("Meal plan models")
struct MealPlanModelTests {
    let context: ModelContext

    init() {
        context = ModelContext(PreviewContainer.shared)
    }

    private func day(_ string: String) throws -> Date {
        try #require(getDateFromString(string))
    }

    @Test("Preview fixtures decode into SwiftData")
    func fixturesDecode() throws {
        let entries = try context.fetch(FetchDescriptor<MealPlanEntry>())
        #expect(entries.count == 12)
        #expect(Set(entries.map(\.type)) == [.recipe, .product, .note])
        let sections = try context.fetch(FetchDescriptor<MDMealPlanSection>())
        #expect(sections.contains { $0.isNoSection && $0.name.isEmpty })
        #expect(sections.sortedForMealPlan.map(\.name) == ["", "Breakfast", "Lunch", "Dinner"])
    }

    @Test(
        "Week names match SQLite's %Y-%W",
        arguments: [
            ("2025-11-23", "2025-46"),  // Sunday
            ("2025-11-24", "2025-47"),  // Monday
            ("2025-11-30", "2025-47"),
            ("2025-01-01", "2025-00"),  // Wednesday before the year's first Monday
            ("2024-01-01", "2024-01"),  // Monday
        ]
    )
    func weekNames(date: String, expected: String) throws {
        #expect(MealPlanNames.weekName(for: try day(date)) == expected)
    }

    @Test("The system config reads the meal plan settings")
    func systemConfig() throws {
        let url = try #require(Bundle.main.url(forResource: "system__config", withExtension: "json"))
        let config = try JSONDecoder().decode(SystemConfig.self, from: Data(contentsOf: url))
        #expect(config.featureFlagRecipesMealplan)
        #expect(config.featureFlagStockPriceTracking)
        #expect(config.energyUnit == "kcal")
        #expect(config.mealPlanFirstDayOfWeek == "")

        let container = try ModelContainer(
            for: SystemConfig.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        container.mainContext.insert(config)
        try container.mainContext.save()
        let stored = try #require(try ModelContext(container).fetch(FetchDescriptor<SystemConfig>()).first)
        #expect(stored.featureFlagRecipesMealplan)
        #expect(stored.featureFlagRecipes)
    }

    @Test("Day and shadow recipe names")
    func dayNames() throws {
        let date = try day("2025-11-24")
        #expect(MealPlanNames.dayName(for: date) == "2025-11-24")
        #expect(MealPlanNames.shadowRecipeName(day: date, entryID: 1) == "2025-11-24#1")
    }

    @Test("The lookup finds the internal recipes of the fixtures")
    func lookupFindsInternalRecipes() throws {
        let lookup = MealPlanLookup(
            recipes: try context.fetch(FetchDescriptor<Recipe>()),
            fulfillments: try context.fetch(FetchDescriptor<RecipeFulfilment>()),
            products: [],
            quantityUnits: [],
            stock: [],
            sections: [],
            systemConfig: nil
        )
        let entry = try #require(try context.fetch(FetchDescriptor<MealPlanEntry>(predicate: #Predicate { $0.id == 1 })).first)
        #expect(lookup.shadowRecipeID(of: entry) != nil)
        #expect(lookup.weekRecipeIDs(for: [try day("2025-11-23"), try day("2025-11-24")]).count == 2)
    }

    @Test("Encoding sends a plain day and only the fields of the type")
    func encoding() throws {
        let entry = MealPlanEntry(id: 5, day: try day("2025-11-24"), type: .note, recipeID: 3, note: "Leftovers", productID: 7)
        let json = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(entry)) as? [String: Any])
        #expect(json["day"] as? String == "2025-11-24")
        #expect(json["note"] as? String == "Leftovers")
        #expect(json["recipe_id"] is NSNull)
        #expect(json["product_id"] is NSNull)
        #expect(json["section_id"] as? Int == -1)
    }
}
