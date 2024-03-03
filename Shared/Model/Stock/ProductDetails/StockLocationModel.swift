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
    @Attribute(.unique) var id: Int
    var productID: Int
    var amount: Double
    var locationID: Int
    var locationName: String
    var locationIsFreezer: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case amount
        case locationID = "location_id"
        case locationName = "location_name"
        case locationIsFreezer = "location_is_freezer"
    }
    
    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            do { self.productID = try container.decode(Int.self, forKey: .productID) } catch { self.productID = try Int(container.decode(String.self, forKey: .productID))! }
            do { self.amount = try container.decode(Double.self, forKey: .amount) } catch { self.amount = try Double(container.decode(String.self, forKey: .amount))! }
            do { self.locationID = try container.decode(Int.self, forKey: .locationID) } catch { self.locationID = try Int(container.decode(String.self, forKey: .locationID))! }
            self.locationName = try container.decode(String.self, forKey: .locationName)
            do {
                self.locationIsFreezer = try container.decode(Bool.self, forKey: .locationIsFreezer)
            } catch {
                do {
                    self.locationIsFreezer = (try container.decode(Int.self, forKey: .locationIsFreezer) == 1)
                } catch {
                    self.locationIsFreezer = ["1", "true"].contains(try container.decode(String.self, forKey: .locationIsFreezer))
                }
            }
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(productID, forKey: .productID)
        try container.encode(amount, forKey: .amount)
        try container.encode(locationID, forKey: .locationID)
        try container.encode(locationName, forKey: .locationName)
        try container.encode(locationIsFreezer, forKey: .locationIsFreezer)
    }
    
    init(
        id: Int,
        productID: Int,
        amount: Double,
        locationID: Int,
        locationName: String,
        locationIsFreezer: Bool
    ) {
        self.id = id
        self.productID = productID
        self.amount = amount
        self.locationID = locationID
        self.locationName = locationName
        self.locationIsFreezer = locationIsFreezer
    }
    
    static func == (lhs: StockLocation, rhs: StockLocation) -> Bool {
        lhs.id == rhs.id &&
        lhs.productID == rhs.productID &&
        lhs.amount == rhs.amount &&
        lhs.locationID == rhs.locationID &&
        lhs.locationName == rhs.locationName &&
        lhs.locationIsFreezer == rhs.locationIsFreezer
    }
}

typealias StockLocations = [StockLocation]
