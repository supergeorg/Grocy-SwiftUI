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
    let productID: Int
    let note: String?
    let amount: Double
    let rowCreatedTimestamp: String
    let shoppingListID, done: Int
    let quID: Int?
    let userfields: [String: String]?

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
