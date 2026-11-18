//
//  StockJournalModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import Foundation
import SwiftData

@Model
class StockJournalEntry: Codable, Equatable {
    var transactionType: TransactionType {
        TransactionType(rawValue: transactionTypeRaw) ?? .purchase
    }

    @Attribute(.unique) var id: Int
    var productID: Int
    var amount: Double
    var bestBeforeDate: Date
    var purchasedDate: Date?
    var usedDate: Date?
    var spoiled: Bool
    var stockID: String
    @Attribute var transactionTypeRaw: String
    var price: Double?
    var undone: Bool
    var undoneTimestamp: String?
    var openedDate: Date?
    var locationID: Int
    var recipeID: Int?
    var correlationID: Int?
    var transactionID: String
    var stockRowID: Int?
    var storeID: Int?
    var userID: Int
    var note: String?
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case amount
        case bestBeforeDate = "best_before_date"
        case purchasedDate = "purchased_date"
        case usedDate = "used_date"
        case spoiled
        case stockID = "stock_id"
        case transactionTypeRaw = "transaction_type"
        case price
        case undone
        case undoneTimestamp = "undone_timestamp"
        case openedDate = "opened_date"
        case rowCreatedTimestamp = "row_created_timestamp"
        case locationID = "location_id"
        case recipeID = "recipe_id"
        case correlationID = "correlation_id"
        case transactionID = "transaction_id"
        case stockRowID = "stock_row_id"
        case storeID = "shopping_location_id"
        case userID = "user_id"
        case note
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.productID = try container.decodeFlexibleInt(forKey: .productID)
            self.amount = try container.decodeFlexibleDouble(forKey: .amount)
            self.bestBeforeDate = getDateFromString(try? container.decodeIfPresent(String.self, forKey: .bestBeforeDate)) ?? Date.neverOverdue
            self.purchasedDate = getDateFromString(try? container.decodeIfPresent(String.self, forKey: .purchasedDate))
            self.usedDate = getDateFromString(try? container.decodeIfPresent(String.self, forKey: .usedDate))
            self.spoiled = try container.decodeFlexibleBool(forKey: .spoiled)
            self.stockID = try container.decodeFlexibleString(forKey: .stockID)
            self.transactionTypeRaw = try container.decode(String.self, forKey: .transactionTypeRaw)
            self.price = try container.decodeFlexibleDoubleIfPresent(forKey: .price)
            self.undone = try container.decodeFlexibleBool(forKey: .undone)
            self.undoneTimestamp = try? container.decodeIfPresent(String.self, forKey: .undoneTimestamp) ?? nil
            self.openedDate = getDateFromString(try? container.decodeIfPresent(String.self, forKey: .openedDate))
            self.locationID = try container.decodeFlexibleInt(forKey: .locationID)
            self.recipeID = try container.decodeFlexibleIntIfPresent(forKey: .recipeID)
            self.correlationID = try container.decodeFlexibleIntIfPresent(forKey: .correlationID)
            self.transactionID = try container.decodeFlexibleString(forKey: .transactionID)
            self.stockRowID = try container.decodeFlexibleIntIfPresent(forKey: .stockRowID)
            self.storeID = try container.decodeFlexibleIntIfPresent(forKey: .storeID)
            self.userID = try container.decodeFlexibleInt(forKey: .userID)
            self.note = try? container.decodeIfPresent(String.self, forKey: .note)
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp))!
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(productID, forKey: .productID)
        try container.encode(amount, forKey: .amount)
        try container.encode(bestBeforeDate, forKey: .bestBeforeDate)
        try container.encode(purchasedDate, forKey: .purchasedDate)
        try container.encode(usedDate, forKey: .usedDate)
        try container.encode(spoiled, forKey: .spoiled)
        try container.encode(stockID, forKey: .stockID)
        try container.encode(transactionTypeRaw, forKey: .transactionTypeRaw)
        try container.encode(price, forKey: .price)
        try container.encode(undone, forKey: .undone)
        try container.encode(undoneTimestamp, forKey: .undoneTimestamp)
        try container.encode(openedDate, forKey: .openedDate)
        try container.encode(locationID, forKey: .locationID)
        try container.encode(recipeID, forKey: .recipeID)
        try container.encode(correlationID, forKey: .correlationID)
        try container.encode(transactionID, forKey: .transactionID)
        try container.encode(stockRowID, forKey: .stockRowID)
        try container.encode(storeID, forKey: .storeID)
        try container.encode(userID, forKey: .userID)
        try container.encode(note, forKey: .note)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    static func == (lhs: StockJournalEntry, rhs: StockJournalEntry) -> Bool {
        lhs.id == rhs.id && lhs.productID == rhs.productID && lhs.amount == rhs.amount && lhs.bestBeforeDate == rhs.bestBeforeDate
            && lhs.purchasedDate == rhs.purchasedDate && lhs.usedDate == rhs.usedDate && lhs.spoiled == rhs.spoiled
            && lhs.stockID == rhs.stockID && lhs.transactionTypeRaw == rhs.transactionTypeRaw && lhs.price == rhs.price && lhs.undone == rhs.undone
            && lhs.undoneTimestamp == rhs.undoneTimestamp && lhs.openedDate == rhs.openedDate
            && lhs.locationID == rhs.locationID && lhs.recipeID == rhs.recipeID && lhs.correlationID == rhs.correlationID
            && lhs.transactionID == rhs.transactionID && lhs.stockRowID == rhs.stockRowID && lhs.storeID == rhs.storeID
            && lhs.userID == rhs.userID && lhs.note == rhs.note && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias StockJournal = [StockJournalEntry]
