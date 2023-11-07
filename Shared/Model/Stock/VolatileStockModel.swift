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
    var dueProducts: [StockElement]
    var overdueProducts: [StockElement]
    var expiredProducts: [StockElement]
    var missingProducts: [VolatileStockProductMissing]

    enum CodingKeys: String, CodingKey {
        case dueProducts = "due_products"
        case overdueProducts = "overdue_products"
        case expiredProducts = "expired_products"
        case missingProducts = "missing_products"
    }
    
    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.dueProducts = try container.decodeIfPresent([StockElement].self, forKey: .dueProducts) ?? []
            self.overdueProducts = try container.decodeIfPresent([StockElement].self, forKey: .overdueProducts) ?? []
            self.expiredProducts = try container.decodeIfPresent([StockElement].self, forKey: .expiredProducts) ?? []
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

// MARK: - VolatileStockProductMissing
//@Model
struct VolatileStockProductMissing: Codable {
    var id: Int
    var name: String?
    var amountMissing: Double
    var isPartlyInStock: Bool

    enum CodingKeys: String, CodingKey {
        case id, name
        case amountMissing = "amount_missing"
        case isPartlyInStock = "is_partly_in_stock"
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = try Int(container.decode(String.self, forKey: .id))! }
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
    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(name, forKey: .name)
//        try container.encode(amountMissing, forKey: .amountMissing)
//        try container.encode(isPartlyInStock, forKey: .isPartlyInStock)
//    }
}
