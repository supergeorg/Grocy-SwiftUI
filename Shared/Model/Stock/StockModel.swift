//
//  StockModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let stock = try? newJSONDecoder().decode(Stock.self, from: jsonData)

import Foundation

//// MARK: - StockElement
//struct StockElement: Codable {
//    let amount, amountAggregated, bestBeforeDate, amountOpened: String
//    let amountOpenedAggregated, isAggregatedAmount, productID: String
//    let product: MDProduct
//
//    enum CodingKeys: String, CodingKey {
//        case amount
//        case amountAggregated = "amount_aggregated"
//        case bestBeforeDate = "best_before_date"
//        case amountOpened = "amount_opened"
//        case amountOpenedAggregated = "amount_opened_aggregated"
//        case isAggregatedAmount = "is_aggregated_amount"
//        case productID = "product_id"
//        case product
//    }
//}
//
//typealias Stock = [StockElement]

// MARK: - StockEntry
struct StockElement: Codable {
    let amount, amountAggregated, value, bestBeforeDate: String
    let amountOpened, amountOpenedAggregated, isAggregatedAmount: String
    let dueType: String
    let productID: String
    let product: MDProduct

    enum CodingKeys: String, CodingKey {
        case amount
        case amountAggregated = "amount_aggregated"
        case value
        case bestBeforeDate = "best_before_date"
        case amountOpened = "amount_opened"
        case amountOpenedAggregated = "amount_opened_aggregated"
        case isAggregatedAmount = "is_aggregated_amount"
        case dueType = "due_type"
        case productID = "product_id"
        case product
    }
}

typealias Stock = [StockElement]
