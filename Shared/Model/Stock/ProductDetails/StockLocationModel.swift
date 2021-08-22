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
                    self.locationIsFreezer = ["1",  "true"].contains(try container.decode(String.self, forKey: .locationIsFreezer))
                }
            }
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
}

typealias StockLocations = [StockLocation]
