//
//  ProductDetailsModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 25.11.20.
//

import Foundation

// MARK: - StockProductDetails
struct StockProductDetails: Codable {
    let product: MDProduct
    let productBarcodes: [MDProductBarcode]
    let lastPurchased, lastUsed: String?
    let stockAmount: Double
    let stockValue: Double?
    let stockAmountOpened: Double?
    let stockAmountAggregated: Double?
    let stockAmountOpenedAggregated: Double?
    let defaultQuantityUnitPurchase: MDQuantityUnit
    let quantityUnitStock: MDQuantityUnit
    let lastPrice, avgPrice, oldestPrice: Double?
    let lastShoppingLocationID: Int?
    let defaultShoppingLocationID: Int?
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
        case lastShoppingLocationID = "last_shopping_location_id"
        case defaultShoppingLocationID = "default_shopping_location_id"
        case nextDueDate = "next_due_date"
        case location
        case averageShelfLifeDays = "average_shelf_life_days"
        case spoilRatePercent = "spoil_rate_percent"
        case isAggregatedAmount = "is_aggregated_amount"
        case hasChilds = "has_childs"
    }
    
    //    Decoder with Numbers instead of strings
    //    init(from decoder: Decoder) throws {
    //        let container = try decoder.container(keyedBy: CodingKeys.self)
    //        self.product = try container.decode(MDProduct.self, forKey: .product)
    //        self.productBarcodes = try container.decode([MDProductBarcode].self, forKey: .productBarcodes)
    //        self.lastPurchased = try? container.decodeIfPresent(String.self, forKey: .lastPurchased) ?? nil
    //        self.lastUsed = try? container.decodeIfPresent(String.self, forKey: .lastUsed) ?? nil
    //        self.stockAmount = try container.decode(Double.self, forKey: .stockAmount)
    //        self.stockValue = try? container.decodeIfPresent(Double.self, forKey: .stockValue) ?? nil
    //        self.stockAmountOpened = try? container.decodeIfPresent(Double.self, forKey: .stockAmountOpened) ?? nil
    //        self.stockAmountAggregated = try? container.decodeIfPresent(Double.self, forKey: .stockAmountAggregated) ?? nil
    //        self.stockAmountOpenedAggregated = try? container.decodeIfPresent(Double.self, forKey: .stockAmountOpenedAggregated) ?? nil
    //        self.defaultQuantityUnitPurchase = try container.decode(MDQuantityUnit.self, forKey: .defaultQuantityUnitPurchase)
    //        self.quantityUnitStock = try container.decode(MDQuantityUnit.self, forKey: .quantityUnitStock)
    //        self.lastPrice = try? container.decodeIfPresent(Double.self, forKey: .lastPrice) ?? nil
    //        self.avgPrice = try? container.decodeIfPresent(Double.self, forKey: .avgPrice) ?? nil
    //        self.oldestPrice = try? container.decodeIfPresent(Double.self, forKey: .oldestPrice) ?? nil
    //        self.lastShoppingLocationID = try? container.decodeIfPresent(Int.self, forKey: .lastShoppingLocationID) ?? nil
    //        self.defaultShoppingLocationID = try? container.decodeIfPresent(Int.self, forKey: .defaultShoppingLocationID) ?? nil
    //        self.nextDueDate = try container.decode(String.self, forKey: .nextDueDate)
    //        self.location = try container.decode(MDLocation.self, forKey: .location)
    //        self.averageShelfLifeDays = try container.decode(Int.self, forKey: .averageShelfLifeDays)
    //        self.spoilRatePercent = try container.decode(Double.self, forKey: .spoilRatePercent)
    //        self.isAggregatedAmount = (try? container.decodeIfPresent(Bool.self, forKey: .isAggregatedAmount) ?? (try? container.decodeIfPresent(Int.self, forKey: .isAggregatedAmount) == 1) ?? false) ?? false
    //        self.hasChilds = (try? container.decodeIfPresent(Bool.self, forKey: .hasChilds) ?? (try? container.decodeIfPresent(Int.self, forKey: .hasChilds) == 1) ?? false) ?? false
    //    }
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.product = try container.decode(MDProduct.self, forKey: .product)
            self.productBarcodes = try container.decode([MDProductBarcode].self, forKey: .productBarcodes)
            self.lastPurchased = try? container.decodeIfPresent(String.self, forKey: .lastPurchased) ?? nil
            self.lastUsed = try? container.decodeIfPresent(String.self, forKey: .lastUsed) ?? nil
            self.stockAmount = try Double(container.decode(String.self, forKey: .stockAmount))!
            self.stockValue = try? Double(container.decodeIfPresent(String.self, forKey: .stockValue) ?? "")
            self.stockAmountOpened = try? Double(container.decodeIfPresent(String.self, forKey: .stockAmountOpened) ?? "")
            self.stockAmountAggregated = try? Double(container.decodeIfPresent(String.self, forKey: .stockAmountAggregated) ?? "")
            self.stockAmountOpenedAggregated = try? Double(container.decodeIfPresent(String.self, forKey: .stockAmountOpenedAggregated) ?? "")
            self.defaultQuantityUnitPurchase = try container.decode(MDQuantityUnit.self, forKey: .defaultQuantityUnitPurchase)
            self.quantityUnitStock = try container.decode(MDQuantityUnit.self, forKey: .quantityUnitStock)
            self.lastPrice = try? Double(container.decodeIfPresent(String.self, forKey: .lastPrice) ?? "")
            self.avgPrice = try? Double(container.decodeIfPresent(String.self, forKey: .avgPrice) ?? "")
            self.oldestPrice = try? Double(container.decodeIfPresent(String.self, forKey: .oldestPrice) ?? "")
            self.lastShoppingLocationID = try? Int(container.decodeIfPresent(String.self, forKey: .lastShoppingLocationID) ?? "")
            self.defaultShoppingLocationID = try? Int(container.decodeIfPresent(String.self, forKey: .defaultShoppingLocationID) ?? "")
            self.nextDueDate = try container.decode(String.self, forKey: .nextDueDate)
            self.location = try container.decode(MDLocation.self, forKey: .location)
            self.averageShelfLifeDays = try Int(container.decode(String.self, forKey: .averageShelfLifeDays))!
            self.spoilRatePercent = try Double(container.decode(String.self, forKey: .spoilRatePercent))!
            self.isAggregatedAmount = (try? container.decodeIfPresent(Bool.self, forKey: .isAggregatedAmount) ?? (try? container.decodeIfPresent(String.self, forKey: .isAggregatedAmount) == "1") ?? false) ?? false
            self.hasChilds = (try? container.decodeIfPresent(Bool.self, forKey: .hasChilds) ?? (try? container.decodeIfPresent(String.self, forKey: .hasChilds) == "1") ?? false) ?? false
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
}
