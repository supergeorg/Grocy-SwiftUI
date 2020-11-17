//
//  VolatileStockModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 09.11.20.
//

import Foundation
// MARK: - VolatileStockElement
struct VolatileStock: Codable {
    let expiringProducts, expiredProducts: [ExpirProduct]
    let missingProducts: [MissingProduct]

    enum CodingKeys: String, CodingKey {
        case expiringProducts = "expiring_products"
        case expiredProducts = "expired_products"
        case missingProducts = "missing_products"
    }
}

// MARK: - ExpirProduct
struct ExpirProduct: Codable {
    let productID, amount, amountAggregated, amountOpened: Int
    let amountOpenedAggregated: Int
    let bestBeforeDate: String
    let isAggregatedAmount: Bool
    let product: MDProduct

    enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case amount
        case amountAggregated = "amount_aggregated"
        case amountOpened = "amount_opened"
        case amountOpenedAggregated = "amount_opened_aggregated"
        case bestBeforeDate = "best_before_date"
        case isAggregatedAmount = "is_aggregated_amount"
        case product
    }
}

// MARK: - MissingProduct
struct MissingProduct: Codable {
    let id: Int
    let name: String
    let amountMissing, isPartlyInStock: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case amountMissing = "amount_missing"
        case isPartlyInStock = "is_partly_in_stock"
    }
}

//typealias VolatileStock = [VolatileStockElement]
