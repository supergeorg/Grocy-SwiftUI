//
//  ProductAddModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.10.20.
//

// Description:
// amount    number($number)
// The amount to add - please note that when tare weight handling for the product is enabled, this needs to be the amount including the container weight (gross), the amount to be posted will be automatically calculated based on what is in stock and the defined tare weight

// best_before_date    string($date)
// The due date of the product to add, when omitted, the current date is used

// transaction_type    string [ purchase, consume, inventory-correction, product-opened ]

// price    number($number)
// The price per stock quantity unit in configured currency

// location_id    number($integer)
// If omitted, the default location of the product is used

// shopping_location_id    number($integer)
// If omitted, no store will be affected

import Foundation

struct ProductBuy: Codable {
    let amount: Double
    let bestBeforeDate: String?
    let transactionType: TransactionType
    let price: Double?
    let locationID: Int?
    let storeID: Int?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case amount
        case bestBeforeDate = "best_before_date"
        case transactionType = "transaction_type"
        case price
        case locationID = "location_id"
        case storeID = "shopping_location_id"
        case note
    }
}
