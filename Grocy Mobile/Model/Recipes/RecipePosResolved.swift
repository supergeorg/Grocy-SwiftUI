//
//  RecipePosResolved.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 06.08.25.
//

import Foundation
import SwiftData

@Model
final class RecipePosResolvedElement: Codable {
    @Attribute(.unique) var id: UUID
    var notRealId: Int
    var recipeID: Int
    var recipePosID: Int
    var productID: Int
    var recipeAmount: Double
    var stockAmount: Double
    var needFulfilled: Bool
    var missingAmount: Double
    var amountOnShoppingList: Double
    var needFulfilledWithShoppingList: Bool
    var quID: Int
    var costs: Double
    var isNestedRecipePos: Bool
    var ingredientGroup: String?
    var productGroup: String
    var recipeType: RecipeType
    var childRecipeID: Int
    var note: String
    var recipeVariableAmount: String
    var onlyCheckSingleUnitInStock: Bool
    var calories: Double
    var productActive: Bool
    var dueScore: Int
    var productIDEffective: Int
    var productName: String

    enum CodingKeys: String, CodingKey {
        case recipeID = "recipe_id"
        case recipePosID = "recipe_pos_id"
        case productID = "product_id"
        case recipeAmount = "recipe_amount"
        case stockAmount = "stock_amount"
        case needFulfilled = "need_fulfilled"
        case missingAmount = "missing_amount"
        case amountOnShoppingList = "amount_on_shopping_list"
        case needFulfilledWithShoppingList = "need_fulfilled_with_shopping_list"
        case quID = "qu_id"
        case costs
        case isNestedRecipePos = "is_nested_recipe_pos"
        case ingredientGroup = "ingredient_group"
        case productGroup = "product_group"
        case notRealId = "id"
        case recipeType = "recipe_type"
        case childRecipeID = "child_recipe_id"
        case note
        case recipeVariableAmount = "recipe_variable_amount"
        case onlyCheckSingleUnitInStock = "only_check_single_unit_in_stock"
        case calories
        case productActive = "product_active"
        case dueScore = "due_score"
        case productIDEffective = "product_id_effective"
        case productName = "product_name"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = UUID()
        notRealId = try container.decodeFlexibleInt(forKey: .notRealId)
        recipeID = try container.decodeFlexibleInt(forKey: .recipeID)
        recipePosID = try container.decodeFlexibleInt(forKey: .recipePosID)
        productID = try container.decodeFlexibleInt(forKey: .productID)
        recipeAmount = try container.decodeFlexibleDouble(forKey: .recipeAmount)
        stockAmount = try container.decodeFlexibleDouble(forKey: .stockAmount)
        needFulfilled = try container.decodeFlexibleBool(forKey: .needFulfilled)
        missingAmount = try container.decodeFlexibleDouble(forKey: .missingAmount)
        amountOnShoppingList = try container.decodeFlexibleDouble(forKey: .amountOnShoppingList)
        needFulfilledWithShoppingList = try container.decodeFlexibleBool(forKey: .needFulfilledWithShoppingList)
        quID = try container.decodeFlexibleInt(forKey: .quID)
        costs = try container.decodeFlexibleDouble(forKey: .costs)
        isNestedRecipePos = try container.decodeFlexibleBool(forKey: .isNestedRecipePos)
        ingredientGroup = try container.decodeIfPresent(String.self, forKey: .ingredientGroup)
        productGroup = try container.decode(String.self, forKey: .productGroup)
        recipeType = try container.decode(RecipeType.self, forKey: .recipeType)
        childRecipeID = try container.decodeFlexibleInt(forKey: .childRecipeID)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        recipeVariableAmount = try container.decodeIfPresent(String.self, forKey: .recipeVariableAmount) ?? ""
        onlyCheckSingleUnitInStock = try container.decodeFlexibleBool(forKey: .onlyCheckSingleUnitInStock)
        calories = try container.decodeFlexibleDouble(forKey: .calories)
        productActive = try container.decodeFlexibleBool(forKey: .productActive)
        dueScore = try container.decodeFlexibleInt(forKey: .dueScore)
        productIDEffective = try container.decodeFlexibleInt(forKey: .productIDEffective)
        productName = try container.decode(String.self, forKey: .productName)
    }

    init(
        notRealId: Int = -1,
        recipeID: Int = -1,
        recipePosID: Int = -1,
        productID: Int = -1,
        recipeAmount: Double = 1.0,
        stockAmount: Double = 1.0,
        needFulfilled: Bool = false,
        missingAmount: Double = 0.0,
        amountOnShoppingList: Double = 0.0,
        needFulfilledWithShoppingList: Bool = false,
        quID: Int = -1,
        costs: Double = 0.0,
        isNestedRecipePos: Bool = false,
        ingredientGroup: String? = nil,
        productGroup: String = "",
        recipeType: RecipeType = .normal,
        childRecipeID: Int = -1,
        note: String = "",
        recipeVariableAmount: String = "",
        onlyCheckSingleUnitInStock: Bool = false,
        calories: Double = 0.0,
        productActive: Bool = true,
        dueScore: Int = 0,
        productIDEffective: Int = 0,
        productName: String = ""
    ) {
        self.id = UUID()
        self.notRealId = notRealId
        self.recipeID = recipeID
        self.recipePosID = recipePosID
        self.productID = productID
        self.recipeAmount = recipeAmount
        self.stockAmount = stockAmount
        self.needFulfilled = needFulfilled
        self.missingAmount = missingAmount
        self.amountOnShoppingList = amountOnShoppingList
        self.needFulfilledWithShoppingList = needFulfilledWithShoppingList
        self.quID = quID
        self.costs = costs
        self.isNestedRecipePos = isNestedRecipePos
        self.ingredientGroup = ingredientGroup
        self.productGroup = productGroup
        self.recipeType = recipeType
        self.childRecipeID = childRecipeID
        self.note = note
        self.recipeVariableAmount = recipeVariableAmount
        self.onlyCheckSingleUnitInStock = onlyCheckSingleUnitInStock
        self.calories = calories
        self.productActive = productActive
        self.dueScore = dueScore
        self.productIDEffective = productIDEffective
        self.productName = productName
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(notRealId, forKey: .notRealId)
        try container.encode(recipeID, forKey: .recipeID)
        try container.encode(recipePosID, forKey: .recipePosID)
        try container.encode(productID, forKey: .productID)
        try container.encode(recipeAmount, forKey: .recipeAmount)
        try container.encode(stockAmount, forKey: .stockAmount)
        try container.encode(needFulfilled, forKey: .needFulfilled)
        try container.encode(missingAmount, forKey: .missingAmount)
        try container.encode(amountOnShoppingList, forKey: .amountOnShoppingList)
        try container.encode(needFulfilledWithShoppingList, forKey: .needFulfilledWithShoppingList)
        try container.encode(quID, forKey: .quID)
        try container.encode(costs, forKey: .costs)
        try container.encode(isNestedRecipePos, forKey: .isNestedRecipePos)
        try container.encodeIfPresent(ingredientGroup, forKey: .ingredientGroup)
        try container.encode(productGroup, forKey: .productGroup)
        try container.encode(recipeType, forKey: .recipeType)
        try container.encode(childRecipeID, forKey: .childRecipeID)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(recipeVariableAmount, forKey: .recipeVariableAmount)
        try container.encode(onlyCheckSingleUnitInStock, forKey: .onlyCheckSingleUnitInStock)
        try container.encode(calories, forKey: .calories)
        try container.encode(productActive, forKey: .productActive)
        try container.encode(dueScore, forKey: .dueScore)
        try container.encode(productIDEffective, forKey: .productIDEffective)
        try container.encode(productName, forKey: .productName)
    }
}

typealias RecipePosResolved = [RecipePosResolvedElement]
