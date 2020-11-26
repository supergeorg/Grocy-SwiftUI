//
//  ShoppingListModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import Foundation

// MARK: - ShoppingListElement
struct ShoppingListItem: Codable {
    let id: String
    let productID, note: String?
    let amount, rowCreatedTimestamp, shoppingListID, done: String
    let quID: String?
    let userfields: String?

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case note, amount
        case rowCreatedTimestamp = "row_created_timestamp"
        case shoppingListID = "shopping_list_id"
        case done
        case quID = "qu_id"
        case userfields
    }
}

typealias ShoppingList = [ShoppingListItem]
