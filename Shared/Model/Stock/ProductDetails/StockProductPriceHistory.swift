//
//  StockProductPriceHistory.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 25.11.20.
//

import Foundation

// MARK: - ProductPriceHistory

struct ProductPriceHistory: Codable {
    let date: String
    let price: Double
    let shoppingLocation: MDShoppingLocation

    enum CodingKeys: String, CodingKey {
        case date, price
        case shoppingLocation = "shopping_location"
    }
}

typealias ProductPriceHistories = [ProductPriceHistory]
