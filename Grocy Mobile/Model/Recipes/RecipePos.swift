//
//  RecipePos.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.08.25.
//

class RecipePos: Codable {
    var id, recipeID, productID: Int
    var amount: Double
    var note: String?
    var quID, onlyCheckSingleUnitInStock: Int
    var ingredientGroup: String?
    var notCheckStockFulfillment: Int
    var rowCreatedTimestamp: String
    var variableAmount: Int?
    var priceFactor: Double
    var roundUp: Int

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

    init(id: Int, recipeID: Int, productID: Int, amount: Double, note: String?, quID: Int, onlyCheckSingleUnitInStock: Int, ingredientGroup: String?, notCheckStockFulfillment: Int, rowCreatedTimestamp: String, variableAmount: Int?, priceFactor: Double, roundUp: Int) {
        self.id = id
        self.recipeID = recipeID
        self.productID = productID
        self.amount = amount
        self.note = note
        self.quID = quID
        self.onlyCheckSingleUnitInStock = onlyCheckSingleUnitInStock
        self.ingredientGroup = ingredientGroup
        self.notCheckStockFulfillment = notCheckStockFulfillment
        self.rowCreatedTimestamp = rowCreatedTimestamp
        self.variableAmount = variableAmount
        self.priceFactor = priceFactor
        self.roundUp = roundUp
    }
}
