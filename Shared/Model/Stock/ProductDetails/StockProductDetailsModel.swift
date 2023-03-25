//
//  ProductDetailsModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 25.11.20.
//

import Foundation

// MARK: - StockProductDetails

struct StockProductDetails: Codable {
    let product: MDProduct
    let productBarcodes: [MDProductBarcode]
    let lastPurchased, lastUsed: Date?
    let stockAmount: Double
    let stockValue: Double?
    let stockAmountOpened: Double?
    let stockAmountAggregated: Double?
    let stockAmountOpenedAggregated: Double?
    let defaultQuantityUnitPurchase: MDQuantityUnit
    let quantityUnitStock: MDQuantityUnit
    let lastPrice, avgPrice, oldestPrice: Double?
    let lastStoreID: Int?
    let defaultStoreID: Int?
    let nextDueDate: String
    let location: MDLocation
    let averageShelfLifeDays: Int
    let spoilRatePercent: Double
    let isAggregatedAmount: Bool
    let hasChilds: Bool

    enum CodingKeys: String, CodingKey {
        case product
        case productBarcodes = "product_barcodes"
        case lastPurchased = "last_purchased"
        case lastUsed = "last_used"
        case stockAmount = "stock_amount"
        case stockValue = "stock_value"
        case stockAmountOpened = "stock_amount_opened"
        case stockAmountAggregated = "stock_amount_aggregated"
        case stockAmountOpenedAggregated = "stock_amount_opened_aggregated"
        case defaultQuantityUnitPurchase = "default_quantity_unit_purchase"
        case quantityUnitStock = "quantity_unit_stock"
        case lastPrice = "last_price"
        case avgPrice = "avg_price"
        case oldestPrice = "oldest_price"
        case lastStoreID = "last_shopping_location_id"
        case defaultStoreID = "default_shopping_location_id"
        case nextDueDate = "next_due_date"
        case location
        case averageShelfLifeDays = "average_shelf_life_days"
        case spoilRatePercent = "spoil_rate_percent"
        case isAggregatedAmount = "is_aggregated_amount"
        case hasChilds = "has_childs"
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.product = try container.decode(MDProduct.self, forKey: .product)
            self.productBarcodes = try container.decode([MDProductBarcode].self, forKey: .productBarcodes)
            if let lastPurchasedTS = try? container.decodeIfPresent(String.self, forKey: .lastPurchased) {
                self.lastPurchased = getDateFromString(lastPurchasedTS)
            } else { self.lastPurchased = nil }
            if let lastUsedTS = try? container.decodeIfPresent(String.self, forKey: .lastUsed) {
                self.lastUsed = getDateFromString(lastUsedTS)
            } else { self.lastUsed = nil }
            do { self.stockAmount = try container.decode(Double.self, forKey: .stockAmount) } catch { self.stockAmount = try Double(container.decode(String.self, forKey: .stockAmount))! }
            do { self.stockValue = try container.decodeIfPresent(Double.self, forKey: .stockValue) } catch { self.stockValue = try? Double(container.decodeIfPresent(String.self, forKey: .stockValue) ?? "") }
            do { self.stockAmountOpened = try container.decodeIfPresent(Double.self, forKey: .stockAmountOpened) } catch { self.stockAmountOpened = try? Double(container.decodeIfPresent(String.self, forKey: .stockAmountOpened) ?? "") }
            do { self.stockAmountAggregated = try container.decodeIfPresent(Double.self, forKey: .stockAmountAggregated) } catch { self.stockAmountAggregated = try? Double(container.decodeIfPresent(String.self, forKey: .stockAmountAggregated) ?? "") }
            do { self.stockAmountOpenedAggregated = try container.decodeIfPresent(Double.self, forKey: .stockAmountOpenedAggregated) } catch { self.stockAmountOpenedAggregated = try? Double(container.decodeIfPresent(String.self, forKey: .stockAmountOpenedAggregated) ?? "") }
            self.defaultQuantityUnitPurchase = try container.decode(MDQuantityUnit.self, forKey: .defaultQuantityUnitPurchase)
            self.quantityUnitStock = try container.decode(MDQuantityUnit.self, forKey: .quantityUnitStock)
            do { self.lastPrice = try container.decodeIfPresent(Double.self, forKey: .lastPrice) } catch { self.lastPrice = try? Double(container.decodeIfPresent(String.self, forKey: .lastPrice) ?? "") }
            do { self.avgPrice = try container.decodeIfPresent(Double.self, forKey: .avgPrice) } catch { self.avgPrice = try? Double(container.decodeIfPresent(String.self, forKey: .avgPrice) ?? "") }
            do { self.oldestPrice = try container.decodeIfPresent(Double.self, forKey: .oldestPrice) } catch { self.oldestPrice = try? Double(container.decodeIfPresent(String.self, forKey: .oldestPrice) ?? "") }
            do { self.lastStoreID = try container.decodeIfPresent(Int.self, forKey: .lastStoreID) } catch { self.lastStoreID = try? Int(container.decodeIfPresent(String.self, forKey: .lastStoreID) ?? "") }
            do { self.defaultStoreID = try container.decodeIfPresent(Int.self, forKey: .defaultStoreID) } catch { self.defaultStoreID = try? Int(container.decodeIfPresent(String.self, forKey: .defaultStoreID) ?? "") }
            self.nextDueDate = try container.decode(String.self, forKey: .nextDueDate)
            self.location = try container.decode(MDLocation.self, forKey: .location)
            do { self.averageShelfLifeDays = try container.decode(Int.self, forKey: .averageShelfLifeDays) } catch { self.averageShelfLifeDays = try Int(container.decode(String.self, forKey: .averageShelfLifeDays))! }
            do { self.spoilRatePercent = try container.decode(Double.self, forKey: .spoilRatePercent) } catch { self.spoilRatePercent = try Double(container.decode(String.self, forKey: .spoilRatePercent))! }
            do {
                self.isAggregatedAmount = try container.decode(Bool.self, forKey: .isAggregatedAmount)
            } catch {
                do {
                    self.isAggregatedAmount = try container.decodeIfPresent(Int.self, forKey: .isAggregatedAmount) == 1
                } catch {
                    self.isAggregatedAmount = ["1", "true"].contains(try container.decodeIfPresent(String.self, forKey: .isAggregatedAmount))
                }
            }
            do {
                self.hasChilds = try container.decode(Bool.self, forKey: .hasChilds)
            } catch {
                do {
                    self.hasChilds = try container.decode(Int.self, forKey: .hasChilds) == 1
                } catch {
                    self.hasChilds = ["1", "true"].contains(try container.decode(String.self, forKey: .hasChilds))
                }
            }
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
}
