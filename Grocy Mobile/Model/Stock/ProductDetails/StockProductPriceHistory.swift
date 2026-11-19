//
//  StockProductPriceHistory.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 25.11.20.
//

import Foundation

// MARK: - ProductPriceHistory

/// One purchase price of a product (`/stock/products/{productId}/price-history`), per stock quantity unit.
///
/// Display-only and fetched on demand, so it isn't stored in SwiftData.
/// Grocy sends the whole store (`shopping_location`), or `null` when the purchase had none; only its ID and name are kept.
struct ProductPriceHistory: Codable, Equatable, Identifiable {
    var id = UUID()
    var date: Date
    var price: Double
    var storeID: Int?
    var storeName: String?

    enum CodingKeys: String, CodingKey {
        case date, price
        case store = "shopping_location"
    }

    private enum StoreKeys: String, CodingKey {
        case id, name
    }

    init(date: Date, price: Double, storeID: Int? = nil, storeName: String? = nil) {
        self.date = date
        self.price = price
        self.storeID = storeID
        self.storeName = storeName
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let dateString = try container.decodeFlexibleString(forKey: .date)
            guard let date = getDateFromString(dateString) else {
                throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Invalid date \(dateString)")
            }
            self.date = date
            self.price = try container.decodeFlexibleDouble(forKey: .price)
            if (try? container.decodeNil(forKey: .store)) == false, container.contains(.store) {
                let store = try container.nestedContainer(keyedBy: StoreKeys.self, forKey: .store)
                self.storeID = try store.decodeFlexibleIntIfPresent(forKey: .id)
                self.storeName = try store.decodeIfPresent(String.self, forKey: .name)
            }
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(price, forKey: .price)
        if storeID != nil || storeName != nil {
            var store = container.nestedContainer(keyedBy: StoreKeys.self, forKey: .store)
            try store.encodeIfPresent(storeID, forKey: .id)
            try store.encodeIfPresent(storeName, forKey: .name)
        } else {
            try container.encodeNil(forKey: .store)
        }
    }

    static func == (lhs: ProductPriceHistory, rhs: ProductPriceHistory) -> Bool {
        lhs.date == rhs.date && lhs.price == rhs.price && lhs.storeID == rhs.storeID && lhs.storeName == rhs.storeName
    }
}

typealias ProductPriceHistories = [ProductPriceHistory]
