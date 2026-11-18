//
//  StockLocationModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 25.11.20.
//

import Foundation
import SwiftData

// MARK: - StockLocation

@Model
class StockLocation: Codable, Equatable {
    @Attribute(.unique) var id: UUID
    var equalID: Int
    var productID: Int
    var amount: Double
    var locationID: Int
    var locationName: String
    var locationIsFreezer: Bool

    enum CodingKeys: String, CodingKey {
        case equalID = "id"
        case productID = "product_id"
        case amount
        case locationID = "location_id"
        case locationName = "location_name"
        case locationIsFreezer = "location_is_freezer"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.id = UUID()
            self.equalID = try container.decodeFlexibleInt(forKey: .equalID)
            self.productID = try container.decodeFlexibleInt(forKey: .productID)
            self.amount = try container.decodeFlexibleDouble(forKey: .amount)
            self.locationID = try container.decodeFlexibleInt(forKey: .locationID)
            self.locationName = try container.decode(String.self, forKey: .locationName)
            self.locationIsFreezer = try container.decodeFlexibleBool(forKey: .locationIsFreezer)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(equalID, forKey: .equalID)
        try container.encode(productID, forKey: .productID)
        try container.encode(amount, forKey: .amount)
        try container.encode(locationID, forKey: .locationID)
        try container.encode(locationName, forKey: .locationName)
        try container.encode(locationIsFreezer, forKey: .locationIsFreezer)
    }

    init(
        id: Int = -1,
        productID: Int = -1,
        amount: Double = 1.0,
        locationID: Int = -1,
        locationName: String = "",
        locationIsFreezer: Bool = false
    ) {
        self.id = UUID()
        self.equalID = id
        self.productID = productID
        self.amount = amount
        self.locationID = locationID
        self.locationName = locationName
        self.locationIsFreezer = locationIsFreezer
    }

    static func == (lhs: StockLocation, rhs: StockLocation) -> Bool {
        lhs.equalID == rhs.equalID && lhs.productID == rhs.productID && lhs.amount == rhs.amount && lhs.locationID == rhs.locationID
            && lhs.locationName == rhs.locationName && lhs.locationIsFreezer == rhs.locationIsFreezer
    }
}

typealias StockLocations = [StockLocation]
