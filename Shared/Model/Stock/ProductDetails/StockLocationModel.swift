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
    let productID: Int
    let amount: Double
    let locationID: Int
    let locationName: String
    let locationIsFreezer: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case amount
        case locationID = "location_id"
        case locationName = "location_name"
        case locationIsFreezer = "location_is_freezer"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.productID = try container.decode(Int.self, forKey: .productID)
        self.amount = try container.decode(Double.self, forKey: .amount)
        self.locationID = try container.decode(Int.self, forKey: .locationID)
        self.locationName = try container.decode(String.self, forKey: .locationName)
        self.locationIsFreezer = (try? container.decodeIfPresent(Bool.self, forKey: .locationIsFreezer) ?? (try? container.decodeIfPresent(Int.self, forKey: .locationIsFreezer) == 1) ?? false) ?? false
    }
}

typealias StockLocations = [StockLocation]
