//
//  ShoppingListDescriptionModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import Foundation

// MARK: - ShoppingListDescription
struct ShoppingListDescription: Codable {
    let id: Int
    let name: String
    let shoppingListDescriptionDescription: String?
    let rowCreatedTimestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case shoppingListDescriptionDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
    }
}

typealias ShoppingListDescriptions = [ShoppingListDescription]
