//
//  ShoppingListAddProduct.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 02.12.20.
//

//product_id    integer
//A valid product id of the item on the shopping list

//list_id    integer
//A valid shopping list id, when omitted, the default shopping list (with id 1) is used

//product_amount    integer
//The amount of product units to add, when omitted, the default amount of 1 is used

//note    string
//The note of the shopping list item

import Foundation

// MARK: - ShoppingListAddProduct
struct ShoppingListAddProduct: Codable {
    let productID, listID, productAmount: Int
    let note: String

    enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case listID = "list_id"
        case productAmount = "product_amount"
        case note
    }
}
