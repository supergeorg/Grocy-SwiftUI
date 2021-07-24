//
//  ShoppingListModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import Foundation

// MARK: - ShoppingListElement
struct ShoppingListItem: Codable {
    let id: Int
    let productID: Int?
    let note: String?
    let amount: Double
    let shoppingListID: Int
    let done: Int
    let quID: Int?
    let rowCreatedTimestamp: String

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case note, amount
        case shoppingListID = "shopping_list_id"
        case done
        case quID = "qu_id"
        case rowCreatedTimestamp = "row_created_timestamp"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.productID = try? container.decodeIfPresent(Int.self, forKey: .productID) ?? nil
        self.note = try? container.decodeIfPresent(String.self, forKey: .note) ?? nil
        self.amount = try container.decode(Double.self, forKey: .amount)
        self.shoppingListID = try container.decode(Int.self, forKey: .shoppingListID)
        self.done = try container.decode(Int.self, forKey: .done)
        self.quID = try? container.decodeIfPresent(Int.self, forKey: .quID) ?? nil
        self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
    }
    
    init(id: Int,
    productID: Int? = nil,
    note: String? = nil,
    amount: Double,
    shoppingListID: Int,
    done: Int,
    quID: Int? = nil,
    rowCreatedTimestamp: String) {
        self.id = id
        self.productID = productID
        self.note = note
        self.amount = amount
        self.shoppingListID = shoppingListID
        self.done = done
        self.quID = quID
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias ShoppingList = [ShoppingListItem]
