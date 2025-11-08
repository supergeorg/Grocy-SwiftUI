//
//  RecipePosResolved.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 06.08.25.
//
import SwiftData

@Model
final class RecipePosResolvedElement: Codable {
    @Attribute(.unique) var id: Int
    var recipeID: Int
    var recipePosID: Int
    var productID: Int
    var recipeAmount: Double
    var stockAmount: Double
    var needFulfilled: Int
    var missingAmount: Int
    var amountOnShoppingList: Int
    var needFulfilledWithShoppingList: Int
    var quID: Int
    var costs: Double
    var isNestedRecipePos: Int
    var ingredientGroup: String?
    var productGroup: MDProductGroup
    var recipeType: RecipeType
    var childRecipeID: Int
    var note: String?
    var recipeVariableAmount: Int?
    var onlyCheckSingleUnitInStock: Int
    var calories: Double
    var productActive: Int
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
        case id
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
        id = try container.decode(Int.self, forKey: .id)
        recipeID = try container.decode(Int.self, forKey: .recipeID)
        recipePosID = try container.decode(Int.self, forKey: .recipePosID)
        productID = try container.decode(Int.self, forKey: .productID)
        recipeAmount = try container.decode(Double.self, forKey: .recipeAmount)
        stockAmount = try container.decode(Double.self, forKey: .stockAmount)
        needFulfilled = try container.decode(Int.self, forKey: .needFulfilled)
        missingAmount = try container.decode(Int.self, forKey: .missingAmount)
        amountOnShoppingList = try container.decode(Int.self, forKey: .amountOnShoppingList)
        needFulfilledWithShoppingList = try container.decode(Int.self, forKey: .needFulfilledWithShoppingList)
        quID = try container.decode(Int.self, forKey: .quID)
        costs = try container.decode(Double.self, forKey: .costs)
        isNestedRecipePos = try container.decode(Int.self, forKey: .isNestedRecipePos)
        ingredientGroup = try container.decodeIfPresent(String.self, forKey: .ingredientGroup)
        productGroup = try container.decode(MDProductGroup.self, forKey: .productGroup)
        recipeType = try container.decode(RecipeType.self, forKey: .recipeType)
        childRecipeID = try container.decode(Int.self, forKey: .childRecipeID)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        recipeVariableAmount = try container.decodeIfPresent(Int.self, forKey: .recipeVariableAmount)
        onlyCheckSingleUnitInStock = try container.decode(Int.self, forKey: .onlyCheckSingleUnitInStock)
        calories = try container.decode(Double.self, forKey: .calories)
        productActive = try container.decode(Int.self, forKey: .productActive)
        dueScore = try container.decode(Int.self, forKey: .dueScore)
        productIDEffective = try container.decode(Int.self, forKey: .productIDEffective)
        productName = try container.decode(String.self, forKey: .productName)
    }
    
    init(id: Int, recipeID: Int, recipePosID: Int, productID: Int, recipeAmount: Double, 
         stockAmount: Double, needFulfilled: Int, missingAmount: Int, amountOnShoppingList: Int,
         needFulfilledWithShoppingList: Int, quID: Int, costs: Double, isNestedRecipePos: Int,
         ingredientGroup: String?, productGroup: MDProductGroup, recipeType: RecipeType,
         childRecipeID: Int, note: String?, recipeVariableAmount: Int?,
         onlyCheckSingleUnitInStock: Int, calories: Double, productActive: Int,
         dueScore: Int, productIDEffective: Int, productName: String) {
        self.id = id
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
        try container.encode(id, forKey: .id)
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
