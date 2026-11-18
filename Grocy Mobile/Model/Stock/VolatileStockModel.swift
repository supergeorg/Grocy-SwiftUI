//
//  VolatileStockModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 09.11.20.
//

import Foundation
import SwiftData

// MARK: - VolatileStock
@Model
class VolatileStock: Codable {
    @Relationship(deleteRule: .cascade) var dueProducts: [VolatileStockElement]
    @Relationship(deleteRule: .cascade) var overdueProducts: [VolatileStockElement]
    @Relationship(deleteRule: .cascade) var expiredProducts: [VolatileStockElement]
    @Relationship(deleteRule: .cascade) var missingProducts: [VolatileStockProductMissing]

    enum CodingKeys: String, CodingKey {
        case dueProducts = "due_products"
        case overdueProducts = "overdue_products"
        case expiredProducts = "expired_products"
        case missingProducts = "missing_products"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.dueProducts = try container.decodeIfPresent([VolatileStockElement].self, forKey: .dueProducts) ?? []
            self.overdueProducts = try container.decodeIfPresent([VolatileStockElement].self, forKey: .overdueProducts) ?? []
            self.expiredProducts = try container.decodeIfPresent([VolatileStockElement].self, forKey: .expiredProducts) ?? []
            self.missingProducts = try container.decodeIfPresent([VolatileStockProductMissing].self, forKey: .missingProducts) ?? []
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dueProducts, forKey: .dueProducts)
        try container.encode(overdueProducts, forKey: .overdueProducts)
        try container.encode(expiredProducts, forKey: .expiredProducts)
        try container.encode(missingProducts, forKey: .missingProducts)
    }

    init(
        dueProducts: [VolatileStockElement] = [],
        overdueProducts: [VolatileStockElement] = [],
        expiredProducts: [VolatileStockElement] = [],
        missingProducts: [VolatileStockProductMissing] = [],
    ) {
        self.dueProducts = dueProducts
        self.overdueProducts = overdueProducts
        self.expiredProducts = expiredProducts
        self.missingProducts = missingProducts
    }
}

@Model
class VolatileStockElement: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id = UUID()
    var amount: Double
    var amountAggregated: Double
    var value: Double
    var bestBeforeDate: Date
    var amountOpened: Double
    var amountOpenedAggregated: Double
    var isAggregatedAmount: Bool
    var dueType: DueType
    var productID: Int

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
    }

    init(
        amount: Double = 1.0,
        amountAggregated: Double = 1.0,
        value: Double = 1.0,
        bestBeforeDate: Date = Date(),
        amountOpened: Double = 0.0,
        amountOpenedAggregated: Double = 0.0,
        isAggregatedAmount: Bool = false,
        dueType: DueType = .bestBefore,
        productID: Int
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
    }

    static func == (lhs: VolatileStockElement, rhs: VolatileStockElement) -> Bool {
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

// MARK: - VolatileStockProductMissing
@Model
class VolatileStockProductMissing: Codable {
    @Attribute(.unique) var id = UUID()
    var productID: Int
    var name: String?
    var amountMissing: Double
    var isPartlyInStock: Bool

    enum CodingKeys: String, CodingKey {
        case id = "volatile_product_missing_id"
        case productID = "id"
        case name
        case amountMissing = "amount_missing"
        case isPartlyInStock = "is_partly_in_stock"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.productID = try container.decodeFlexibleInt(forKey: .productID)
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
            self.amountMissing = try container.decodeFlexibleDouble(forKey: .amountMissing)
            self.isPartlyInStock = try container.decodeFlexibleBool(forKey: .isPartlyInStock)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(productID, forKey: .productID)
        try container.encode(name, forKey: .name)
        try container.encode(amountMissing, forKey: .amountMissing)
        try container.encode(isPartlyInStock, forKey: .isPartlyInStock)
    }
}
