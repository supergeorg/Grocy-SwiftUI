//
//  ShoppingListAddProduct.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 02.12.20.
//

import Foundation

// MARK: - ShoppingListAddProduct
struct ShoppingListAddProduct: Codable {
    let productID, listID: Int
    let productAmount: Double
    let note: String

    enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case listID = "list_id"
        case productAmount = "product_amount"
        case note
    }
}
