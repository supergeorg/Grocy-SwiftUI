//
//  VolatileStockModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 09.11.20.
//

// Not used for now

import Foundation

// MARK: - VolatileStock

struct VolatileStock: Codable {
    let dueProducts, overdueProducts, expiredProducts: [StockElement]
    let missingProducts: [VolatileStockProductMissing]

    enum CodingKeys: String, CodingKey {
        case dueProducts = "due_products"
        case overdueProducts = "overdue_products"
        case expiredProducts = "expired_products"
        case missingProducts = "missing_products"
    }
}

// MARK: - VolatileStockProductMissing

struct VolatileStockProductMissing: Codable {
    let id: Int
    let name: String?
    let amountMissing: Double
    let isPartlyInStock: Bool

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
}
