//
//  ShoppingListModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 26.11.20.
//

import Foundation
import SwiftData

@Model
class ShoppingListItem: Codable, Equatable {
    @Attribute(.unique) var id: Int
    var productID: Int?
    var note: String
    var amount: Double
    var shoppingListID: Int
    var done: Bool
    var quID: Int?
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case note, amount
        case shoppingListID = "shopping_list_id"
        case done
        case quID = "qu_id"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.productID = try container.decodeFlexibleIntIfPresent(forKey: .productID)
            self.note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
            self.amount = try container.decodeFlexibleDouble(forKey: .amount)
            self.shoppingListID = try container.decodeFlexibleInt(forKey: .shoppingListID)
            self.done = try container.decodeFlexibleBool(forKey: .done)
            self.quID = try container.decodeFlexibleIntIfPresent(forKey: .quID)
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp))!
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(productID, forKey: .productID)
        try container.encode(note, forKey: .note)
        try container.encode(amount, forKey: .amount)
        try container.encode(shoppingListID, forKey: .shoppingListID)
        try container.encode(done, forKey: .done)
        try container.encode(quID, forKey: .quID)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    init(
        id: Int = -1,
        productID: Int? = nil,
        note: String = "",
        amount: Double = 1.0,
        shoppingListID: Int = -1,
        done: Bool = false,
        quID: Int = -1,
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.productID = productID
        self.note = note
        self.amount = amount
        self.shoppingListID = shoppingListID
        self.done = done
        self.quID = quID
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    static func == (lhs: ShoppingListItem, rhs: ShoppingListItem) -> Bool {
        lhs.id == rhs.id && lhs.productID == rhs.productID && lhs.note == rhs.note && lhs.amount == rhs.amount && lhs.shoppingListID == rhs.shoppingListID
            && lhs.done == rhs.done && lhs.quID == rhs.quID && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}
