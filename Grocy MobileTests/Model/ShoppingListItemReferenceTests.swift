//
//  ShoppingListItemReferenceTests.swift
//  Grocy Mobile
//

import Foundation
import Testing

@testable import Grocy_Mobile

/// A free-text shopping list item has no product and no unit. Older app versions saved -1 for both, which Grocy keeps.
@MainActor
@Suite("Shopping list item: empty product and unit")
struct ShoppingListItemReferenceTests {
    private func item(productID: String, quID: String) throws -> ShoppingListItem {
        let json = """
            {"id": 1, "product_id": \(productID), "note": "Bread", "amount": 1, "shopping_list_id": 1, "done": 0,
             "qu_id": \(quID), "row_created_timestamp": "2026-11-25 08:00:00"}
            """
        return try JSONDecoder().decode(ShoppingListItem.self, from: Data(json.utf8))
    }

    @Test("-1, 0, an empty string and null are read as no product and no unit", arguments: ["-1", "0", "\"\"", "null"])
    func emptyReferences(value: String) throws {
        let item = try item(productID: value, quID: value)
        #expect(item.productID == nil)
        #expect(item.quID == nil)
    }

    @Test("A product and unit are kept")
    func references() throws {
        let item = try item(productID: "5", quID: "2")
        #expect(item.productID == 5)
        #expect(item.quID == 2)
    }

    @Test("A new free-text item is sent without product and unit")
    func newItemEncodesNull() throws {
        let data = try JSONEncoder().encode(ShoppingListItem(note: "Bread", shoppingListID: 1))
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["product_id"] is NSNull)
        #expect(object["qu_id"] is NSNull)
    }
}
