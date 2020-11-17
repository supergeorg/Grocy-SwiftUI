//
//  ProductAddModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 20.10.20.
//

import Foundation

struct ProductBuy: Codable {
    let amount: Int
    let bestBeforeDate: String
    let transactionType: String
    let price: String?
    let locationID, shoppingLocationID: Int?

    enum CodingKeys: String, CodingKey {
        case amount
        case bestBeforeDate = "best_before_date"
        case transactionType = "transaction_type"
        case price
        case locationID = "location_id"
        case shoppingLocationID = "shopping_location_id"
    }
}
