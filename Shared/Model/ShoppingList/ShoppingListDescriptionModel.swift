//
//  ShoppingListDescriptionModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 26.11.20.
//

import Foundation
import SwiftData

@Model
class ShoppingListDescription: Codable {
    @Attribute(.unique) var id: Int
    var name: String
    var rowCreatedTimestamp: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do {
                self.id = try container.decode(Int.self, forKey: .id)
            } catch {
                self.id = Int(try container.decode(String.self, forKey: .id))!
            }
            self.name = try container.decode(String.self, forKey: .name)
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    init(
        id: Int,
        name: String,
        rowCreatedTimestamp: String
    ) {
        self.id = id
        self.name = name
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias ShoppingListDescriptions = [ShoppingListDescription]
