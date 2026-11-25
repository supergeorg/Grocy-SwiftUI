//
//  ShoppingListDescriptionModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 26.11.20.
//

import Foundation
import SwiftData

@Model
class ShoppingListDescription: Codable, Equatable {
    @Attribute(.unique) var id: Int
    var name: String
    /// The list's notes from Grocy's web shopping list, as rich-text HTML. Read-only in the app: it isn't encoded,
    /// so saving the list here (a rename) never overwrites the web's formatting. The default lets SwiftData add the column.
    var notes: String? = nil
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case notes = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.notes = try? container.decodeIfPresent(String.self, forKey: .notes)
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp)) ?? .distantPast
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
        id: Int = -1,
        name: String = "",
        notes: String? = nil,
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    static func == (lhs: ShoppingListDescription, rhs: ShoppingListDescription) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.notes == rhs.notes && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias ShoppingListDescriptions = [ShoppingListDescription]
