//
//  PreviewContainer.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.25.
//

import Foundation
import SwiftData
import SwiftUI

struct PreviewDataTrait: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        return PreviewContainer.shared
    }

    let grocyVM = GrocyViewModel(modelContext: PreviewContainer.shared.mainContext, profileModelContext: PreviewContainer.shared.mainContext)

    func body(content: Content, context: ModelContainer) -> some View {
        content
            .grocyFeatures()
            .environment(grocyVM)
            .modelContainer(PreviewContainer.shared)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var previewData: Self = .modifier(PreviewDataTrait())
}

@MainActor
struct PreviewContainer {
    static let modelTypes: [any PersistentModel.Type] = [
        MDLocation.self,
        MDProductGroup.self,
        MDProduct.self,
        MDQuantityUnitConversion.self,
        MDQuantityUnit.self,
        ShoppingListItem.self,
        ShoppingListDescription.self,
        MDStore.self,
        StockEntry.self,
        StockJournalEntry.self,
        Recipe.self,
        RecipeNesting.self,
        MDChore.self,
        MDTaskCategory.self,
        GrocyTask.self,
        StockElement.self,
        VolatileStock.self,
        GrocyUser.self,
        RecipeFulfilment.self,
        Chore.self,
        ChoreLogEntry.self,
        MDBattery.self,
        Battery.self,
        BatteryChargeCycle.self,
        MDEquipment.self,
        MealPlanEntry.self,
        MDMealPlanSection.self,
        SystemConfig.self,
        GrocyUserSettings.self,
    ]

    static let shared: ModelContainer = {
        #if DEBUG
            do {
                let schema = Schema(modelTypes)

                let container = try ModelContainer(
                    for: schema,
                    configurations: .init(isStoredInMemoryOnly: true, cloudKitDatabase: .none),
                )
                seedData(container: container)

                return container
            } catch {
                fatalError("Failed to create preview container: \(error)")
            }
        #else
            fatalError("Failed to create preview container.")
        #endif
    }()

    private static func seedData(container: ModelContainer) {
        let context = container.mainContext

        // Clear any existing data before seeding
        clearExistingData(from: context)

        // Objects
        loadAndInsert(modelType: MDLocation.self, filename: "objects__locations.json", into: context)
        loadAndInsert(modelType: MDProductGroup.self, filename: "objects__product_groups.json", into: context)
        loadAndInsert(modelType: MDProduct.self, filename: "objects__products.json", into: context)
        loadAndInsert(modelType: MDQuantityUnitConversion.self, filename: "objects__quantity_unit_conversions.json", into: context)
        loadAndInsert(modelType: MDQuantityUnit.self, filename: "objects__quantity_units.json", into: context)
        loadAndInsert(modelType: ShoppingListItem.self, filename: "objects__shopping_list.json", into: context)
        loadAndInsert(modelType: ShoppingListDescription.self, filename: "objects__shopping_lists.json", into: context)
        loadAndInsert(modelType: MDStore.self, filename: "objects__shopping_locations.json", into: context)
        loadAndInsert(modelType: StockEntry.self, filename: "objects__stock.json", into: context)
        loadAndInsert(modelType: StockJournalEntry.self, filename: "objects__stock_log.json", into: context)
        loadAndInsert(modelType: Recipe.self, filename: "objects__recipes.json", into: context)
        loadAndInsert(modelType: MDChore.self, filename: "objects__chores.json", into: context)
        loadAndInsert(modelType: MDTaskCategory.self, filename: "objects__task_categories.json", into: context)
        loadAndInsert(modelType: ChoreLogEntry.self, filename: "objects__chores_log.json", into: context)
        loadAndInsert(modelType: MDBattery.self, filename: "objects__batteries.json", into: context)
        loadAndInsert(modelType: BatteryChargeCycle.self, filename: "objects__battery_charge_cycles.json", into: context)
        loadAndInsert(modelType: MDEquipment.self, filename: "objects__equipment.json", into: context)
        loadAndInsert(modelType: MealPlanEntry.self, filename: "objects__meal_plan.json", into: context)
        loadAndInsert(modelType: MDMealPlanSection.self, filename: "objects__meal_plan_sections.json", into: context)

        // Other
        loadAndInsert(modelType: StockElement.self, filename: "stock.json", into: context)
        loadAndInsert(modelType: VolatileStock.self, filename: "stock__volatile.json", into: context, singleElement: true)
        loadAndInsert(modelType: GrocyUser.self, filename: "users.json", into: context)
        loadAndInsert(modelType: RecipeFulfilment.self, filename: "recipes__fulfillment.json", into: context)
        loadAndInsert(modelType: Chore.self, filename: "chores.json", into: context)
        loadAndInsert(modelType: Battery.self, filename: "batteries.json", into: context)

        try? context.save()
    }

    private static func clearExistingData(from context: ModelContext) {
        for modelType in modelTypes {
            do {
                try context.delete(model: modelType)
            } catch {
                print("⚠️ Failed to clear \(modelType): \(error)")
            }
        }
    }

    private static func loadAndInsert<T>(
        modelType: T.Type,
        filename: String,
        into context: ModelContext,
        singleElement: Bool = false
    ) where T: PersistentModel & Decodable {
        guard let fileURL = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".json", with: ""), withExtension: "json") else {
            print("⚠️ Could not find \(filename).")
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()

            if singleElement {
                let item = try decoder.decode(T.self, from: data)
                context.insert(item)
            } else {
                let items = try decoder.decode([T].self, from: data)

                for item in items {
                    context.insert(item)
                }
            }
        } catch {
            print("⚠️ Failed to decode \(filename): \(error)")
        }
    }
}
