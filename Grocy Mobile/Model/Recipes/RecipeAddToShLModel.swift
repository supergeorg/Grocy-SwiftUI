//
//  RecipeAddToShLModel.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 29.03.26.
//

struct RecipeAddToShLModel: Codable {
    var excludedProductIds: [Int] = []

    enum CodingKeys: String, CodingKey {
        case excludedProductIds = "excludedProductIds"
    }
}
