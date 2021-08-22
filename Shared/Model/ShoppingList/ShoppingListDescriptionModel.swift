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
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do {
                self.id = try container.decode(Int.self, forKey: .id)
            } catch {
                self.id = Int(try container.decode(String.self, forKey: .id))!
            }
            self.name = try container.decode(String.self, forKey: .name)
            self.shoppingListDescriptionDescription = try? container.decodeIfPresent(String.self, forKey: .shoppingListDescriptionDescription) ?? nil
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    init(id: Int,
         name: String,
         shoppingListDescriptionDescription: String? = nil,
         rowCreatedTimestamp: String) {
        self.id = id
        self.name = name
        self.shoppingListDescriptionDescription = shoppingListDescriptionDescription
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias ShoppingListDescriptions = [ShoppingListDescription]
