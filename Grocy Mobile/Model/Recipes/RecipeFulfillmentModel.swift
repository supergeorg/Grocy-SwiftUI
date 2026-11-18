//
//  RecipeFulfillmentModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 09.12.22.
//

import Foundation
import SwiftData

@Model
class RecipeFulfilment: Codable, Identifiable {
    @Attribute(.unique) var id: UUID
    var equalID: Int
    var recipeID: Int
    var needFulfilled: Bool
    var needFulfilledWithShoppingList: Bool
    var missingProductsCount: Int?
    var costs: Double?
    var costsPerServing: Double?
    var calories: Double?
    var dueScore: Int?
    var productNamesCommaSeparated: String?

    enum CodingKeys: String, CodingKey {
        case equalID = "id"
        case recipeID = "recipe_id"
        case needFulfilled = "need_fulfilled"
        case needFulfilledWithShoppingList = "need_fulfilled_with_shopping_list"
        case missingProductsCount = "missing_products_count"
        case costs
        case costsPerServing = "costs_per_serving"
        case calories
        case dueScore = "due_score"
        case productNamesCommaSeparated = "product_names_comma_separated"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.id = UUID()
            self.equalID = try container.decodeFlexibleInt(forKey: .equalID)
            self.recipeID = try container.decodeFlexibleInt(forKey: .recipeID)
            self.needFulfilled = try container.decodeFlexibleBool(forKey: .needFulfilled)
            self.needFulfilledWithShoppingList = try container.decodeFlexibleBool(forKey: .needFulfilledWithShoppingList)
            self.missingProductsCount = try container.decodeFlexibleIntIfPresent(forKey: .missingProductsCount)
            self.costs = try container.decodeFlexibleDoubleIfPresent(forKey: .costs)
            self.costsPerServing = try container.decodeFlexibleDoubleIfPresent(forKey: .costsPerServing)
            self.calories = try container.decodeFlexibleDoubleIfPresent(forKey: .calories)
            self.dueScore = try container.decodeFlexibleIntIfPresent(forKey: .dueScore)
            self.productNamesCommaSeparated = try? container.decodeIfPresent(String.self, forKey: .productNamesCommaSeparated) ?? nil
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        equalID: Int = 1,
        recipeID: Int,
        needFulfilled: Bool = false,
        needFulfilledWithShoppingList: Bool = false,
        missingProductsCount: Int? = nil,
        costs: Double? = nil,
        costsPerServing: Double? = nil,
        calories: Double? = nil,
        dueScore: Int? = nil,
        productNamesCommaSeparated: String? = nil,
    ) {
        self.id = UUID()
        self.equalID = equalID
        self.recipeID = recipeID
        self.needFulfilled = needFulfilled
        self.needFulfilledWithShoppingList = needFulfilledWithShoppingList
        self.missingProductsCount = missingProductsCount
        self.costs = costs
        self.costsPerServing = costsPerServing
        self.calories = calories
        self.dueScore = dueScore
        self.productNamesCommaSeparated = productNamesCommaSeparated
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .equalID)
        try container.encode(recipeID, forKey: .recipeID)
        try container.encode(needFulfilled, forKey: .needFulfilled)
        try container.encode(needFulfilledWithShoppingList, forKey: .needFulfilledWithShoppingList)
        try container.encode(missingProductsCount, forKey: .missingProductsCount)
        try container.encode(costs, forKey: .costs)
        try container.encode(costsPerServing, forKey: .costsPerServing)
        try container.encode(calories, forKey: .calories)
        try container.encode(dueScore, forKey: .dueScore)
        try container.encode(productNamesCommaSeparated, forKey: .productNamesCommaSeparated)
    }
}

typealias RecipeFulfilments = [RecipeFulfilment]
