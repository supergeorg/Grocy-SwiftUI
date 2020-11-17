//
//  StockEntriesModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 23.10.20.
//

import Foundation

struct StockEntry: Codable {
    let id, productID, amount, bestBeforeDate: String
    let purchasedDate, stockID: String
    let price: String?
    let stockEntryOpen: String
    let openedDate: String?
    let rowCreatedTimestamp, locationID: String
    let shoppingLocationID: String?

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
}

typealias StockEntries = [StockEntry]
