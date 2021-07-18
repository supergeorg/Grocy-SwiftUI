//
//  ProductInventoryModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 07.12.20.
//

//new_amount    integer
//The new current amount for the given product - please note that when tare weight handling for the product is enabled, this needs to be the amount including the container weight (gross), the amount to be posted will be automatically calculated based on what is in stock and the defined tare weight

//best_before_date    string($date)
//The due date which applies to added products

//shopping_location_id    number($integer)
//If omitted, no store will be affected

//location_id    number($integer)
//If omitted, the default location of the product is used (only applies to added products)

//price    number($number)
//If omitted, the last price of the product is used (only applies to added products)

import Foundation

// MARK: - ProductInventory
struct ProductInventory: Codable {
    let newAmount: Double
    let bestBeforeDate: String
    let shoppingLocationID, locationID: Int?
    let price: Double?

    enum CodingKeys: String, CodingKey {
        case newAmount = "new_amount"
        case bestBeforeDate = "best_before_date"
        case shoppingLocationID = "shopping_location_id"
        case locationID = "location_id"
        case price
    }
}
