//
//  ShoppingListActionModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 02.12.20.
//

// list_id    integer
// The shopping list id to clear, when omitted, the default shopping list (with id 1) is used

import Foundation

// MARK: - ShoppingListAction

struct ShoppingListAction: Codable {
    let listID: Int

    enum CodingKeys: String, CodingKey {
        case listID = "list_id"
    }
}

struct ShoppingListClearAction: Codable {
    let listID: Int
    let doneOnly: Bool

    enum CodingKeys: String, CodingKey {
        case listID = "list_id"
        case doneOnly = "done_only"
    }
}
