//
//  MealPlanEntryModel.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import Foundation
import SwiftData

/// What a meal plan entry plans: a recipe, a product or a free note.
enum MealPlanEntryType: String, Codable, CaseIterable, Identifiable {
    case recipe
    case product
    case note

    var id: Self { self }
}

/// An entry of the meal plan (`/objects/meal_plan`), planned for a day and a section (e.g. breakfast).
///
/// For every recipe entry, Grocy creates an internal "shadow" recipe (`MealPlanNames.shadowRecipe`) that nests the
/// recipe with the entry's servings. Its fulfillment tells whether the entry's ingredients are in stock, and consuming
/// it consumes them.
@Model
class MealPlanEntry: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var day: Date
    var type: MealPlanEntryType
    var recipeID: Int?
    var recipeServings: Double
    var note: String
    var productID: Int?
    /// In the product's stock quantity unit.
    var productAmount: Double
    var productQuID: Int?
    var done: Bool
    /// `MDMealPlanSection.noSectionID` when the entry has no section.
    var sectionID: Int
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case day
        case type
        case recipeID = "recipe_id"
        case recipeServings = "recipe_servings"
        case note
        case productID = "product_id"
        case productAmount = "product_amount"
        case productQuID = "product_qu_id"
        case done
        case sectionID = "section_id"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.day = getDateFromString(try container.decode(String.self, forKey: .day)) ?? Date()
            self.type = MealPlanEntryType(rawValue: try container.decodeIfPresent(String.self, forKey: .type) ?? "") ?? .recipe
            self.recipeID = try container.decodeFlexibleIntIfPresent(forKey: .recipeID)
            self.recipeServings = try container.decodeFlexibleDoubleIfPresent(forKey: .recipeServings) ?? 1
            self.note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
            self.productID = try container.decodeFlexibleIntIfPresent(forKey: .productID)
            self.productAmount = try container.decodeFlexibleDoubleIfPresent(forKey: .productAmount) ?? 0
            self.productQuID = try container.decodeFlexibleIntIfPresent(forKey: .productQuID)
            self.done = try container.decodeFlexibleBoolIfPresent(forKey: .done) ?? false
            self.sectionID = try container.decodeFlexibleIntIfPresent(forKey: .sectionID) ?? MDMealPlanSection.noSectionID
            self.rowCreatedTimestamp = getDateFromString(try container.decodeIfPresent(String.self, forKey: .rowCreatedTimestamp)) ?? Date()
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int = -1,
        day: Date = Calendar.current.startOfDay(for: Date()),
        type: MealPlanEntryType = .recipe,
        recipeID: Int? = nil,
        recipeServings: Double = 1,
        note: String = "",
        productID: Int? = nil,
        productAmount: Double = 1,
        productQuID: Int? = nil,
        done: Bool = false,
        sectionID: Int = MDMealPlanSection.noSectionID,
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.day = day
        self.type = type
        self.recipeID = recipeID
        self.recipeServings = recipeServings
        self.note = note
        self.productID = productID
        self.productAmount = productAmount
        self.productQuID = productQuID
        self.done = done
        self.sectionID = sectionID
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    /// An unmanaged copy, so a form can edit it without changing the stored entry before it's saved.
    convenience init(copying entry: MealPlanEntry) {
        self.init(
            id: entry.id,
            day: entry.day,
            type: entry.type,
            recipeID: entry.recipeID,
            recipeServings: entry.recipeServings,
            note: entry.note,
            productID: entry.productID,
            productAmount: entry.productAmount,
            productQuID: entry.productQuID,
            done: entry.done,
            sectionID: entry.sectionID,
            rowCreatedTimestamp: entry.rowCreatedTimestamp
        )
    }

    /// Only the fields of the entry's type are sent, the others are cleared, as the Grocy web app does.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        // Always a plain day; Grocy compares it as text with the names of its internal recipes.
        try container.encode(MealPlanNames.dayName(for: day), forKey: .day)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(type == .recipe ? recipeID : nil, forKey: .recipeID)
        try container.encode(recipeServings, forKey: .recipeServings)
        try container.encode(type == .note ? note : nil, forKey: .note)
        try container.encode(type == .product ? productID : nil, forKey: .productID)
        try container.encode(type == .product ? productAmount : 0, forKey: .productAmount)
        try container.encode(type == .product ? productQuID : nil, forKey: .productQuID)
        try container.encode(done, forKey: .done)
        try container.encode(sectionID, forKey: .sectionID)
    }

    static func == (lhs: MealPlanEntry, rhs: MealPlanEntry) -> Bool {
        lhs.id == rhs.id
            && lhs.day == rhs.day
            && lhs.type == rhs.type
            && lhs.recipeID == rhs.recipeID
            && lhs.recipeServings == rhs.recipeServings
            && lhs.note == rhs.note
            && lhs.productID == rhs.productID
            && lhs.productAmount == rhs.productAmount
            && lhs.productQuID == rhs.productQuID
            && lhs.done == rhs.done
            && lhs.sectionID == rhs.sectionID
            && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias MealPlanEntries = [MealPlanEntry]

/// Marks a meal plan entry as done or not done.
struct MealPlanDoneModel: Codable {
    let done: Bool
}

/// Adds a product to a shopping list, or raises the amount of its existing item (`/stock/shoppinglist/add-product`).
struct ShoppingListAddProductModel: Codable {
    let productID: Int
    let listID: Int
    let productAmount: Double
    let note: String?

    enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case listID = "list_id"
        case productAmount = "product_amount"
        case note
    }
}
