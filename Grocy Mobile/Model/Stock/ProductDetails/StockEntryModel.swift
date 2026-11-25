//
//  StockEntriesModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 23.10.20.
//

import Foundation
import SwiftData

@Model
class StockEntry: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var productID: Int
    var amount: Double
    var bestBeforeDate: Date
    var purchasedDate: Date?
    var stockID: String
    var price: Double?
    var stockEntryOpen: Bool
    var openedDate: Date?
    var locationID: Int?
    var storeID: Int?
    var note: String
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case amount
        case bestBeforeDate = "best_before_date"
        case purchasedDate = "purchased_date"
        case stockID = "stock_id"
        case price
        case stockEntryOpen = "open"
        case openedDate = "opened_date"
        case rowCreatedTimestamp = "row_created_timestamp"
        case locationID = "location_id"
        case storeID = "shopping_location_id"
        case note
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.productID = try container.decodeFlexibleInt(forKey: .productID)
            self.amount = try container.decodeFlexibleDouble(forKey: .amount)
            self.bestBeforeDate = getDateFromString(try container.decodeIfPresent(String.self, forKey: .bestBeforeDate)) ?? Date.neverOverdue
            self.purchasedDate = getDateFromString(try? container.decodeIfPresent(String.self, forKey: .purchasedDate))
            self.stockID = try container.decodeFlexibleString(forKey: .stockID)
            self.price = try container.decodeFlexibleDoubleIfPresent(forKey: .price)
            self.stockEntryOpen = try container.decodeFlexibleBool(forKey: .stockEntryOpen)
            self.openedDate = getDateFromString(try? container.decodeIfPresent(String.self, forKey: .openedDate))
            self.locationID = try container.decodeFlexibleIntIfPresent(forKey: .locationID)
            self.storeID = try container.decodeFlexibleIntIfPresent(forKey: .storeID)
            self.note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp)) ?? .distantPast
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int = -1,
        productID: Int = -1,
        amount: Double = 1.0,
        bestBeforeDate: Date = Date(),
        purchasedDate: Date? = nil,
        stockID: String = "",
        price: Double? = nil,
        stockEntryOpen: Bool = false,
        openedDate: Date? = nil,
        locationID: Int? = nil,
        storeID: Int? = nil,
        note: String = "",
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.productID = productID
        self.amount = amount
        self.bestBeforeDate = bestBeforeDate
        self.purchasedDate = purchasedDate
        self.stockID = stockID
        self.price = price
        self.stockEntryOpen = stockEntryOpen
        self.openedDate = openedDate
        self.locationID = locationID
        self.storeID = storeID
        self.note = note
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(productID, forKey: .productID)
        try container.encode(amount, forKey: .amount)
        try container.encode(bestBeforeDate, forKey: .bestBeforeDate)
        try container.encode(purchasedDate, forKey: .purchasedDate)
        try container.encode(stockID, forKey: .stockID)
        try container.encode(price, forKey: .price)
        try container.encode(stockEntryOpen, forKey: .stockEntryOpen)
        try container.encode(openedDate, forKey: .openedDate)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
        try container.encode(locationID, forKey: .locationID)
        try container.encode(storeID, forKey: .storeID)
        try container.encode(note, forKey: .note)
    }
}

typealias StockEntries = [StockEntry]
