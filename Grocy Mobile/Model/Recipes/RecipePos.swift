//
//  RecipePos.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.08.25.
//

import Foundation
import SwiftData

@Model
class RecipePos: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var recipeID: Int
    var productID: Int?
    var amount: Double
    var note: String
    var quID: Int?
    var onlyCheckSingleUnitInStock: Bool
    var ingredientGroup: String
    var notCheckStockFulfillment: Bool
    var variableAmount: String
    var priceFactor: Double
    var roundUp: Bool
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case recipeID = "recipe_id"
        case productID = "product_id"
        case amount, note
        case quID = "qu_id"
        case onlyCheckSingleUnitInStock = "only_check_single_unit_in_stock"
        case ingredientGroup = "ingredient_group"
        case notCheckStockFulfillment = "not_check_stock_fulfillment"
        case rowCreatedTimestamp = "row_created_timestamp"
        case variableAmount = "variable_amount"
        case priceFactor = "price_factor"
        case roundUp = "round_up"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeFlexibleInt(forKey: .id)
        recipeID = try container.decodeFlexibleInt(forKey: .recipeID)
        productID = try container.decodeFlexibleIntIfPresent(forKey: .productID)
        amount = try container.decodeFlexibleDouble(forKey: .amount)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        quID = try container.decodeFlexibleIntIfPresent(forKey: .quID)
        onlyCheckSingleUnitInStock = try container.decodeFlexibleBool(forKey: .onlyCheckSingleUnitInStock)
        ingredientGroup = try container.decodeIfPresent(String.self, forKey: .ingredientGroup) ?? ""
        notCheckStockFulfillment = try container.decodeFlexibleBool(forKey: .notCheckStockFulfillment)
        variableAmount = try container.decodeIfPresent(String.self, forKey: .variableAmount) ?? ""
        priceFactor = try container.decodeFlexibleDouble(forKey: .priceFactor)
        roundUp = try container.decodeFlexibleBool(forKey: .roundUp)
        rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp)) ?? .distantPast
    }

    init(
        id: Int = -1,
        recipeID: Int = -1,
        productID: Int? = nil,
        amount: Double = 1.0,
        note: String = "",
        quID: Int = -1,
        onlyCheckSingleUnitInStock: Bool = false,
        ingredientGroup: String = "",
        notCheckStockFulfillment: Bool = false,
        rowCreatedTimestamp: Date = Date(),
        variableAmount: String = "",
        priceFactor: Double = 1.0,
        roundUp: Bool = false,
    ) {
        self.id = id
        self.recipeID = recipeID
        self.productID = productID
        self.amount = amount
        self.note = note
        self.quID = quID
        self.onlyCheckSingleUnitInStock = onlyCheckSingleUnitInStock
        self.ingredientGroup = ingredientGroup
        self.notCheckStockFulfillment = notCheckStockFulfillment
        self.variableAmount = variableAmount
        self.priceFactor = priceFactor
        self.roundUp = roundUp
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(recipeID, forKey: .recipeID)
        try container.encode(productID, forKey: .productID)
        try container.encode(amount, forKey: .amount)
        try container.encode(note, forKey: .note)
        try container.encode(quID, forKey: .quID)
        try container.encode(onlyCheckSingleUnitInStock, forKey: .onlyCheckSingleUnitInStock)
        try container.encode(ingredientGroup, forKey: .ingredientGroup)
        try container.encode(notCheckStockFulfillment, forKey: .notCheckStockFulfillment)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
        try container.encode(variableAmount, forKey: .variableAmount)
        try container.encode(priceFactor, forKey: .priceFactor)
        try container.encode(roundUp, forKey: .roundUp)
    }
}
