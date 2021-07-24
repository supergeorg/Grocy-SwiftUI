//
//  StockEntriesModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 23.10.20.
//

import Foundation

// MARK: - StockEntry
struct StockEntry: Codable {
    let id, productID: Int
    let amount: Double
    let bestBeforeDate: String
    let purchasedDate: String?
    let stockID: String
    let price: Double?
    let stockEntryOpen: Int
    let openedDate: String?
    let rowCreatedTimestamp: String
    let locationID: Int?
    let shoppingLocationID: Int?

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
        case shoppingLocationID = "shopping_location_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.productID = try container.decode(Int.self, forKey: .productID)
        self.amount = try container.decode(Double.self, forKey: .amount)
        self.bestBeforeDate = try container.decode(String.self, forKey: .bestBeforeDate)
        self.purchasedDate = try? container.decodeIfPresent(String.self, forKey: .purchasedDate) ?? nil
        self.stockID = try container.decode(String.self, forKey: .stockID)
        self.price = try? container.decodeIfPresent(Double.self, forKey: .price) ?? nil
        self.stockEntryOpen = try container.decode(Int.self, forKey: .stockEntryOpen)
        self.openedDate = try? container.decodeIfPresent(String.self, forKey: .openedDate) ?? nil
        self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        self.locationID = try? container.decodeIfPresent(Int.self, forKey: .locationID) ?? nil
        self.shoppingLocationID = try? container.decodeIfPresent(Int.self, forKey: .shoppingLocationID) ?? nil
    }
}

typealias StockEntries = [StockEntry]
