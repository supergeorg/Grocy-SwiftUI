//
//  StockEntriesModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 23.10.20.
//

//id    integer

//product_id    integer

//location_id    integer

//shopping_location_id    integer

//amount    number

//best_before_date    string($date)

//purchased_date    string($date)

//stock_id    string
//A unique id which references this stock entry during its lifetime

//price    number

//open    integer

//opened_date    string($date)

//row_created_timestamp    string($date-time)

import Foundation

// MARK: - StockEntry
struct StockEntry: Codable {
    let id, productID: Int
    let amount: Double
    let bestBeforeDate: String
    let purchasedDate: String
    let stockID: String
    let price: Double?
    let stockEntryOpen: Int
    let openedDate: String?
    let rowCreatedTimestamp: String
    let locationID: Int?
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
