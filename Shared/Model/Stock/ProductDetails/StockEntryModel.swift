//
//  StockEntriesModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 23.10.20.
//

import Foundation

// MARK: - StockEntry
struct StockEntry: Codable, Equatable {
    let id: Int
    let productID: Int
    let amount: Double
    let bestBeforeDate: Date?
    let purchasedDate: Date?
    let stockID: String
    let price: Double?
    let stockEntryOpen: Bool
    let openedDate: Date?
    let rowCreatedTimestamp: String
    let locationID: Int?
    let shoppingLocationID: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case amount
        case bestBeforeDate = "best_before_date"
        case purchasedDate = "purchased_date"
        case stockID = "stock_id"
        case price
        case stockEntryOpen = "open"
        case openedDate = "opened_date"
        case rowCreatedTimestamp = "row_created_timestamp"
        case locationID = "location_id"
        case shoppingLocationID = "shopping_location_id"
    }
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            do { self.productID = try container.decode(Int.self, forKey: .productID) } catch { self.productID = try Int(container.decode(String.self, forKey: .productID))! }
            do { self.amount = try container.decode(Double.self, forKey: .amount) } catch { self.amount = try Double(container.decode(String.self, forKey: .amount))! }
            if let bestBeforeDateString = try? container.decode(String.self, forKey: .bestBeforeDate) {
                self.bestBeforeDate = getDateFromString(bestBeforeDateString)
            } else {
                self.bestBeforeDate = nil
            }
            
            let purchasedDateString = try? container.decodeIfPresent(String.self, forKey: .purchasedDate)
            self.purchasedDate = getDateFromString(purchasedDateString ?? "")
            do { self.stockID = try container.decode(String.self, forKey: .stockID) } catch { self.stockID = try String(container.decode(Int.self, forKey: .stockID)) }
            do { self.price = try container.decodeIfPresent(Double.self, forKey: .price) } catch { self.price = try? Double(container.decodeIfPresent(String.self, forKey: .price) ?? "") }
            do {
                self.stockEntryOpen = try container.decode(Bool.self, forKey: .stockEntryOpen)
            } catch {
                do {
                    self.stockEntryOpen = try (container.decode(String.self, forKey: .stockEntryOpen)) == "1"
                } catch {
                    self.stockEntryOpen = try (container.decode(Int.self, forKey: .stockEntryOpen)) == 1
                }
            }
            let openedDateString = try? container.decodeIfPresent(String.self, forKey: .openedDate)
            self.openedDate = getDateFromString(openedDateString ?? "")
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
            do { self.locationID = try container.decodeIfPresent(Int.self, forKey: .locationID) } catch { self.locationID = try? Int(container.decodeIfPresent(String.self, forKey: .locationID) ?? "") }
            do { self.shoppingLocationID = try container.decodeIfPresent(Int.self, forKey: .shoppingLocationID) } catch { self.shoppingLocationID = try? Int(container.decodeIfPresent(String.self, forKey: .shoppingLocationID) ?? "") }
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    init(id: Int,
         productID: Int,
         amount: Double,
         bestBeforeDate: Date,
         purchasedDate: Date?,
         stockID: String,
         price: Double?,
         stockEntryOpen: Bool,
         openedDate: Date?,
         rowCreatedTimestamp: String,
         locationID: Int? = nil,
         shoppingLocationID: Int? = nil) {
        self.id = id
        self.productID = productID
        self.amount = amount
        self.bestBeforeDate = bestBeforeDate
        self.purchasedDate = purchasedDate
        self.stockID = stockID
        self.price = price
        self.stockEntryOpen = stockEntryOpen
        self.openedDate = openedDate
        self.rowCreatedTimestamp = rowCreatedTimestamp
        self.locationID = locationID
        self.shoppingLocationID = shoppingLocationID
    }
}

typealias StockEntries = [StockEntry]
