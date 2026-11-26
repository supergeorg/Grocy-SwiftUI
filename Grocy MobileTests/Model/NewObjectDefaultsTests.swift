//
//  NewObjectDefaultsTests.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 26.11.26.
//

import Foundation
import Testing

@testable import Grocy_Mobile

/// New objects send null for references that aren't chosen. Grocy stores -1 as it is, as a reference to an object that doesn't exist.
@MainActor
@Suite("New object defaults")
struct NewObjectDefaultsTests {
    private func encodedObject(_ value: some Encodable) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test("A shopping list note without a product sends no product and no unit")
    func shoppingListNote() throws {
        let object = try encodedObject(ShoppingListItem(note: "Bags", shoppingListID: 1))
        #expect(object["product_id"] is NSNull)
        #expect(object["qu_id"] is NSNull)
    }

    @Test("A new ingredient has no unit until a product is chosen")
    func ingredientUnit() throws {
        #expect(RecipePos(recipeID: 1).quID == nil)
        #expect(try encodedObject(RecipePos(recipeID: 1))["qu_id"] is NSNull)
    }
}
