//
//  Untitled.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 07.12.25.
//

import Foundation
import SwiftData

@Model
class RecipeNesting: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var recipeID: Int
    var includesRecipeID: Int
    var servings: Double
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case recipeID = "recipe_id"
        case includesRecipeID = "includes_recipe_id"
        case rowCreatedTimestamp = "row_created_timestamp"
        case servings
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeFlexibleInt(forKey: .id)
        self.recipeID = try container.decodeFlexibleInt(forKey: .recipeID)
        self.includesRecipeID = try container.decodeFlexibleInt(forKey: .includesRecipeID)
        self.servings = try container.decodeFlexibleDouble(forKey: .servings)
        rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp)) ?? .distantPast
    }

    init(
        id: Int = -1,
        recipeID: Int = -1,
        includesRecipeID: Int = -1,
        servings: Double = 1.0,
        rowCreatedTimestamp: Date = Date(),
    ) {
        self.id = id
        self.recipeID = recipeID
        self.includesRecipeID = includesRecipeID
        self.servings = servings
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(recipeID, forKey: .recipeID)
        try container.encode(includesRecipeID, forKey: .includesRecipeID)
        try container.encode(servings, forKey: .servings)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }
}

typealias RecipesNesting = [RecipeNesting]
