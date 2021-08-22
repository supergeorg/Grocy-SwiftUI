//
//  StockModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

// MARK: - StockEntry
struct StockElement: Codable {
    let amount: Double
    let amountAggregated: Double
    let value: Double
    let bestBeforeDate: String
    let amountOpened: Double
    let amountOpenedAggregated: Double
    let isAggregatedAmount: Bool
    let dueType: Int
    let productID: Int
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
    
    //    Decoder with Numbers instead of strings
    //    init(from decoder: Decoder) throws {
    //        let container = try decoder.container(keyedBy: CodingKeys.self)
    //        self.amount = try container.decode(Double.self, forKey: .amount)
    //        self.amountAggregated = try container.decode(Double.self, forKey: .amountAggregated)
    //        self.value = try container.decode(Double.self, forKey: .value)
    //        self.bestBeforeDate = try container.decode(String.self, forKey: .bestBeforeDate)
    //        self.amountOpened = try container.decode(Double.self, forKey: .amountOpened)
    //        self.amountOpenedAggregated = try container.decode(Double.self, forKey: .amountOpenedAggregated)
    //        self.isAggregatedAmount = (try? container.decodeIfPresent(Bool.self, forKey: .isAggregatedAmount) ?? (try? container.decodeIfPresent(Int.self, forKey: .isAggregatedAmount) == 1) ?? false) ?? false
    //        self.dueType = try container.decode(Int.self, forKey: .dueType)
    //        self.productID = try container.decode(Int.self, forKey: .productID)
    //        self.product = try container.decode(MDProduct.self, forKey: .product)
    //    }
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.amount = try Double(container.decode(String.self, forKey: .amount))!
            self.amountAggregated = try Double(container.decode(String.self, forKey: .amountAggregated))!
            self.value = try Double(container.decode(String.self, forKey: .value))!
            self.bestBeforeDate = try container.decode(String.self, forKey: .bestBeforeDate)
            self.amountOpened = try Double(container.decode(String.self, forKey: .amountOpened))!
            self.amountOpenedAggregated = try Double(container.decode(String.self, forKey: .amountOpenedAggregated))!
            self.isAggregatedAmount = (try? container.decodeIfPresent(Bool.self, forKey: .isAggregatedAmount) ?? (try? container.decodeIfPresent(String.self, forKey: .isAggregatedAmount) == "1") ?? false) ?? false
            self.dueType = try Int(container.decode(String.self, forKey: .dueType))!
            self.productID = try Int(container.decode(String.self, forKey: .productID))!
            self.product = try container.decode(MDProduct.self, forKey: .product)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    init(amount: Double,
         amountAggregated: Double,
         value: Double,
         bestBeforeDate: String,
         amountOpened: Double,
         amountOpenedAggregated: Double,
         isAggregatedAmount: Bool,
         dueType: Int,
         productID: Int,
         product: MDProduct) {
        self.amount = amount
        self.amountAggregated = amountAggregated
        self.value = value
        self.bestBeforeDate = bestBeforeDate
        self.amountOpened = amountOpened
        self.amountOpenedAggregated = amountOpenedAggregated
        self.isAggregatedAmount = isAggregatedAmount
        self.dueType = dueType
        self.productID = productID
        self.product = product
    }
}

typealias Stock = [StockElement]
