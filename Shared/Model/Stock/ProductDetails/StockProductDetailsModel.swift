//
//  ProductDetailsModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 25.11.20.
//

import Foundation

// MARK: - StockProductDetails
struct StockProductDetails: Codable {
    let product: MDProduct
    let productBarcodes: [MDProductBarcode]
    let lastPurchased, lastUsed: String?
    let stockAmount: String
    let stockAmountOpened: String?
    let defaultQuantityUnitPurchase, quantityUnitStock: MDQuantityUnit
    let lastPrice, avgPrice, oldestPrice, lastShoppingLocationID: String?
    let nextDueDate: String
    let location: MDLocation
    let averageShelfLifeDays, spoilRatePercent: Int

    enum CodingKeys: String, CodingKey {
        case product
        case productBarcodes = "product_barcodes"
        case lastPurchased = "last_purchased"
        case lastUsed = "last_used"
        case stockAmount = "stock_amount"
        case stockAmountOpened = "stock_amount_opened"
        case defaultQuantityUnitPurchase = "default_quantity_unit_purchase"
        case quantityUnitStock = "quantity_unit_stock"
        case lastPrice = "last_price"
        case avgPrice = "avg_price"
        case oldestPrice = "oldest_price"
        case lastShoppingLocationID = "last_shopping_location_id"
        case nextDueDate = "next_due_date"
        case location
        case averageShelfLifeDays = "average_shelf_life_days"
        case spoilRatePercent = "spoil_rate_percent"
    }
}
