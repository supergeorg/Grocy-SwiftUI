//
//  StockModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation
//import SwiftData
//
//@Model
class StockElement: Codable, Identifiable {
//    @Attribute(.unique) var id = UUID()
    var id = UUID()
    var amount: Double
    var amountAggregated: Double
    var value: Double
    var bestBeforeDate: Date?
    var amountOpened: Double
    var amountOpenedAggregated: Double
    var isAggregatedAmount: Bool
    var dueType: Int
    var productID: Int
    var product: MDProduct

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

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.amount = try container.decode(Double.self, forKey: .amount) } catch { self.amount = try Double(container.decode(String.self, forKey: .amount))! }
            do { self.amountAggregated = try container.decode(Double.self, forKey: .amountAggregated) } catch { self.amountAggregated = try Double(container.decode(String.self, forKey: .amountAggregated))! }
            do { self.value = try container.decode(Double.self, forKey: .value) } catch { self.value = try Double(container.decode(String.self, forKey: .value))! }
            let bestBeforeDateStr = try container.decodeIfPresent(String.self, forKey: .bestBeforeDate)
            self.bestBeforeDate = getDateFromString(bestBeforeDateStr ?? "")
            do { self.amountOpened = try container.decode(Double.self, forKey: .amountOpened) } catch { self.amountOpened = try Double(container.decode(String.self, forKey: .amountOpened))! }
            do { self.amountOpenedAggregated = try container.decode(Double.self, forKey: .amountOpenedAggregated) } catch { self.amountOpenedAggregated = try Double(container.decode(String.self, forKey: .amountOpenedAggregated))! }
            do {
                self.isAggregatedAmount = try container.decode(Bool.self, forKey: .isAggregatedAmount)
            } catch {
                do {
                    self.isAggregatedAmount = try container.decode(Int.self, forKey: .isAggregatedAmount) == 1
                } catch {
                    self.isAggregatedAmount = ["1", "true"].contains(try? container.decode(String.self, forKey: .isAggregatedAmount))
                }
            }
            do { self.dueType = try container.decode(Int.self, forKey: .dueType) } catch { self.dueType = try Int(container.decode(String.self, forKey: .dueType))! }
            do { self.productID = try container.decode(Int.self, forKey: .productID) } catch { self.productID = try Int(container.decode(String.self, forKey: .productID))! }
            self.product = try container.decode(MDProduct.self, forKey: .product)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
        try container.encode(amountAggregated, forKey: .amountAggregated)
        try container.encode(value, forKey: .value)
        try container.encode(bestBeforeDate, forKey: .bestBeforeDate)
        try container.encode(amountOpened, forKey: .amountOpened)
        try container.encode(amountOpenedAggregated, forKey: .amountOpenedAggregated)
        try container.encode(isAggregatedAmount, forKey: .isAggregatedAmount)
        try container.encode(dueType, forKey: .dueType)
        try container.encode(productID, forKey: .productID)
        try container.encode(product, forKey: .product)
    }

    init(
        amount: Double,
        amountAggregated: Double,
        value: Double,
        bestBeforeDate: Date?,
        amountOpened: Double,
        amountOpenedAggregated: Double,
        isAggregatedAmount: Bool,
        dueType: Int,
        productID: Int,
        product: MDProduct
    ) {
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
