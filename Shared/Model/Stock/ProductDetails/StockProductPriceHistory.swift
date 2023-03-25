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
    let store: MDStore

    enum CodingKeys: String, CodingKey {
        case date, price
        case store = "shopping_location"
    }
}

typealias ProductPriceHistories = [ProductPriceHistory]
