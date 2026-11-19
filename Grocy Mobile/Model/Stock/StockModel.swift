//
//  StockModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation
import SwiftData

@Model
class StockElement: Codable, Equatable {
    @Attribute(.unique) var id = UUID()
    var amount: Double
    var amountAggregated: Double
    var value: Double
    var bestBeforeDate: Date?
    var amountOpened: Double
    var amountOpenedAggregated: Double
    var isAggregatedAmount: Bool
    var dueType: DueType
    var productID: Int
    /// The stored link to the product, set by `SwiftDataSynchronizer` for the server's stock.
    @Relationship(deleteRule: .nullify, originalName: "product") private var storedProduct: MDProduct?
    /// The product of a display-only element (see `init(notInStock:)`). Not a relationship: linking a new object to a
    /// stored product inserts it into the product's context, so a display-only element would end up in the store.
    @Transient private var displayProduct: MDProduct? = nil

    var product: MDProduct? {
        get { storedProduct ?? displayProduct }
        set { storedProduct = newValue }
    }

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
            self.amount = try container.decodeFlexibleDouble(forKey: .amount)
            self.amountAggregated = try container.decodeFlexibleDouble(forKey: .amountAggregated)
            self.value = try container.decodeFlexibleDouble(forKey: .value)
            self.bestBeforeDate = getDateFromString(try container.decodeIfPresent(String.self, forKey: .bestBeforeDate)) ?? Date.neverOverdue
            self.amountOpened = try container.decodeFlexibleDouble(forKey: .amountOpened)
            self.amountOpenedAggregated = try container.decodeFlexibleDouble(forKey: .amountOpenedAggregated)
            self.isAggregatedAmount = try container.decodeFlexibleBool(forKey: .isAggregatedAmount)
            self.dueType = DueType(rawValue: try container.decodeFlexibleInt(forKey: .dueType))!
            self.productID = try container.decodeFlexibleInt(forKey: .productID)
            self.storedProduct = nil
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
        amount: Double = 0.0,
        amountAggregated: Double = 0.0,
        value: Double = 0.0,
        bestBeforeDate: Date? = Date(),
        amountOpened: Double = 0.0,
        amountOpenedAggregated: Double = 0.0,
        isAggregatedAmount: Bool = false,
        dueType: DueType = .bestBefore,
        productID: Int = -1,
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

    /// A display-only element with amount 0, for a product that isn't in stock (the stock overview's products below their
    /// minimum stock amount or, with "show all out of stock products", every other product). It stays out of SwiftData.
    init(notInStock product: MDProduct) {
        self.amount = 0
        self.amountAggregated = 0
        self.value = 0
        self.bestBeforeDate = nil
        self.amountOpened = 0
        self.amountOpenedAggregated = 0
        self.isAggregatedAmount = false
        self.dueType = product.dueType
        self.productID = product.id
        self.displayProduct = product
    }

    static func == (lhs: StockElement, rhs: StockElement) -> Bool {
        lhs.amount == rhs.amount && lhs.amountAggregated == rhs.amountAggregated && lhs.value == rhs.value && lhs.bestBeforeDate == rhs.bestBeforeDate
            && lhs.amountOpened == rhs.amountOpened
            && lhs.amountOpenedAggregated == rhs.amountOpenedAggregated && lhs.isAggregatedAmount == rhs.isAggregatedAmount && lhs.dueType == rhs.dueType
            && lhs.productID == rhs.productID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(productID)
    }
}

typealias Stock = [StockElement]
