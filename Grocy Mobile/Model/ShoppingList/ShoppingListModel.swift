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
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp)) ?? .distantPast
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
        quID: Int? = nil,
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

    /// The amount in the unit `quID`.
    ///
    /// Grocy stores a product's amount in the product's stock unit, and `quID` is only the unit it's shown in (#114).
    /// Keeps the amount for free-text items and when there's no conversion.
    func amount(in quID: Int?, product: MDProduct?, conversions: MDQuantityUnitConversions) -> Double {
        guard let product, let quID,
            let factor = QuantityUnitConversionResolver(product: product, conversions: conversions).factor(from: product.quIDStock, to: quID)
        else { return amount }
        return amount * factor
    }

    /// The amount to purchase, in the product's purchase unit, which the purchase form starts with.
    func purchaseAmount(product: MDProduct?, conversions: MDQuantityUnitConversions) -> Double {
        amount(in: product?.quIDPurchase, product: product, conversions: conversions)
    }

    /// The amount as the shopping list shows it: in the item's unit, and rounded up to a whole number when the
    /// Grocy user setting "shopping_list_round_up" is on, like Grocy's own shopping list.
    func displayAmount(roundUp: Bool, product: MDProduct? = nil, conversions: MDQuantityUnitConversions = []) -> Double {
        let amount = amount(in: quID, product: product, conversions: conversions)
        return roundUp ? amount.rounded(.up) : amount
    }

    static func == (lhs: ShoppingListItem, rhs: ShoppingListItem) -> Bool {
        lhs.id == rhs.id && lhs.productID == rhs.productID && lhs.note == rhs.note && lhs.amount == rhs.amount && lhs.shoppingListID == rhs.shoppingListID
            && lhs.done == rhs.done && lhs.quID == rhs.quID && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}
