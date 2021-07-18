//
//  StockLocationModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 25.11.20.
//

import Foundation

// MARK: - StockLocation
struct StockLocation: Codable {
    let id: Int
    let productID, amount, locationID: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case amount
        case locationID = "location_id"
        case name
    }
}

typealias StockLocations = [StockLocation]
