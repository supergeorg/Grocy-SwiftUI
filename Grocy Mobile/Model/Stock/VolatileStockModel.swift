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
}

@Model
class VolatileStockElement: Codable, Equatable {
    @Attribute(.unique) var id = UUID()
    var amount: Double
    var amountAggregated: Double
    var value: Double
    var bestBeforeDate: Date?
    var amountOpened: Double
    var amountOpenedAggregated: Double
    var isAggregatedAmount: Bool
    var dueType: Int
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
        amount: Double,
        amountAggregated: Double,
        value: Double,
        bestBeforeDate: Date?,
        amountOpened: Double,
        amountOpenedAggregated: Double,
        isAggregatedAmount: Bool,
        dueType: Int,
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
        lhs.amount == rhs.amount &&
        lhs.amountAggregated == rhs.amountAggregated &&
        lhs.value == rhs.value &&
        lhs.bestBeforeDate == rhs.bestBeforeDate &&
        lhs.amountOpened == rhs.amountOpened &&
        lhs.amountOpenedAggregated == rhs.amountOpenedAggregated &&
        lhs.isAggregatedAmount == rhs.isAggregatedAmount &&
        lhs.dueType == rhs.dueType &&
        lhs.productID == rhs.productID
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
            do { self.productID = try container.decode(Int.self, forKey: .productID) } catch { self.productID = try Int(container.decode(String.self, forKey: .productID))! }
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
            do { self.amountMissing = try container.decode(Double.self, forKey: .amountMissing) } catch { self.amountMissing = try Double(container.decode(String.self, forKey: .amountMissing))! }
            do {
                self.isPartlyInStock = try container.decode(Bool.self, forKey: .isPartlyInStock)
            } catch {
                do {
                    self.isPartlyInStock = try container.decode(Int.self, forKey: .isPartlyInStock) == 1
                } catch {
                    self.isPartlyInStock = ["1", "true"].contains(try? container.decode(String.self, forKey: .isPartlyInStock))
                }
            }
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
