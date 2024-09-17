//
//  StockJournalModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import Foundation
import SwiftData

@Model
class StockJournalEntry: Codable, Equatable {
    @Attribute(.unique) var id: Int
    var productID: Int
    var amount: Double
    var bestBeforeDate: String?
    var purchasedDate: String?
    var usedDate: String?
    var spoiled: Int
    var stockID: String
    var transactionType: TransactionType
    var price: Double?
    var undone: Int
    var undoneTimestamp: String?
    var openedDate: String?
    var locationID: Int
    var recipeID: Int?
    var correlationID: Int?
    var transactionID: String
    var stockRowID: Int?
    var storeID: Int?
    var userID: Int
    var note: String?
    var rowCreatedTimestamp: String

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case amount
        case bestBeforeDate = "best_before_date"
        case purchasedDate = "purchased_date"
        case usedDate = "used_date"
        case spoiled
        case stockID = "stock_id"
        case transactionType = "transaction_type"
        case price
        case undone
        case undoneTimestamp = "undone_timestamp"
        case openedDate = "opened_date"
        case rowCreatedTimestamp = "row_created_timestamp"
        case locationID = "location_id"
        case recipeID = "recipe_id"
        case correlationID = "correlation_id"
        case transactionID = "transaction_id"
        case stockRowID = "stock_row_id"
        case storeID = "shopping_location_id"
        case userID = "user_id"
        case note
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            do { self.productID = try container.decode(Int.self, forKey: .productID) } catch { self.productID = try Int(container.decode(String.self, forKey: .productID))! }
            do { self.amount = try container.decode(Double.self, forKey: .amount) } catch { self.amount = try Double(container.decode(String.self, forKey: .amount))! }
            self.bestBeforeDate = try? container.decode(String.self, forKey: .bestBeforeDate)
            self.purchasedDate = try? container.decodeIfPresent(String.self, forKey: .purchasedDate) ?? nil
            self.usedDate = try? container.decodeIfPresent(String.self, forKey: .usedDate) ?? nil
            do { self.spoiled = try container.decode(Int.self, forKey: .spoiled) } catch { self.spoiled = try Int(container.decode(String.self, forKey: .spoiled))! }
            do { self.stockID = try container.decode(String.self, forKey: .stockID) } catch { self.stockID = try String(container.decode(Int.self, forKey: .stockID)) }
            self.transactionType = try container.decode(TransactionType.self, forKey: .transactionType)
            do { self.price = try container.decodeIfPresent(Double.self, forKey: .price) } catch { self.price = try? Double(container.decodeIfPresent(String.self, forKey: .price) ?? "") }
            do { self.undone = try container.decode(Int.self, forKey: .undone) } catch { self.undone = try Int(container.decode(String.self, forKey: .undone))! }
            self.undoneTimestamp = try? container.decodeIfPresent(String.self, forKey: .undoneTimestamp) ?? nil
            self.openedDate = try? container.decodeIfPresent(String.self, forKey: .openedDate) ?? nil
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
            do { self.locationID = try container.decode(Int.self, forKey: .locationID) } catch { self.locationID = try Int(container.decode(String.self, forKey: .locationID))! }
            do { self.recipeID = try container.decodeIfPresent(Int.self, forKey: .recipeID) } catch { self.recipeID = try? Int(container.decodeIfPresent(String.self, forKey: .recipeID) ?? "") }
            do { self.correlationID = try container.decodeIfPresent(Int.self, forKey: .correlationID) } catch { self.correlationID = try? Int(container.decodeIfPresent(String.self, forKey: .correlationID) ?? "") }
            do { self.transactionID = try container.decode(String.self, forKey: .transactionID) } catch { self.transactionID = try String(container.decode(Int.self, forKey: .transactionID)) }
            do { self.stockRowID = try container.decodeIfPresent(Int.self, forKey: .stockRowID) } catch { self.stockRowID = try? Int(container.decodeIfPresent(String.self, forKey: .stockRowID) ?? "") }
            do { self.storeID = try container.decodeIfPresent(Int.self, forKey: .storeID) } catch { self.storeID = try? Int(container.decodeIfPresent(String.self, forKey: .storeID) ?? "") }
            do { self.userID = try container.decode(Int.self, forKey: .userID) } catch { self.userID = try Int(container.decode(String.self, forKey: .userID))! }
            self.note = try? container.decodeIfPresent(String.self, forKey: .note)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(productID, forKey: .productID)
        try container.encode(amount, forKey: .amount)
        try container.encode(bestBeforeDate, forKey: .bestBeforeDate)
        try container.encode(purchasedDate, forKey: .purchasedDate)
        try container.encode(usedDate, forKey: .usedDate)
        try container.encode(spoiled, forKey: .spoiled)
        try container.encode(stockID, forKey: .stockID)
        try container.encode(transactionType, forKey: .transactionType)
        try container.encode(price, forKey: .price)
        try container.encode(undone, forKey: .undone)
        try container.encode(undoneTimestamp, forKey: .undoneTimestamp)
        try container.encode(openedDate, forKey: .openedDate)
        try container.encode(locationID, forKey: .locationID)
        try container.encode(recipeID, forKey: .recipeID)
        try container.encode(correlationID, forKey: .correlationID)
        try container.encode(transactionID, forKey: .transactionID)
        try container.encode(stockRowID, forKey: .stockRowID)
        try container.encode(storeID, forKey: .storeID)
        try container.encode(userID, forKey: .userID)
        try container.encode(note, forKey: .note)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }
    
    static func == (lhs: StockJournalEntry, rhs: StockJournalEntry) -> Bool {
        lhs.id == rhs.id &&
        lhs.productID == rhs.productID &&
        lhs.amount == rhs.amount &&
        lhs.bestBeforeDate == rhs.bestBeforeDate &&
        lhs.purchasedDate == rhs.purchasedDate &&
        lhs.usedDate == rhs.usedDate &&
        lhs.spoiled == rhs.spoiled &&
        lhs.stockID == rhs.stockID &&
        lhs.transactionType == rhs.transactionType &&
        lhs.price == rhs.price &&
        lhs.undone == rhs.undone &&
        lhs.undoneTimestamp == rhs.undoneTimestamp &&
        lhs.openedDate == rhs.openedDate &&
        lhs.locationID == rhs.locationID &&
        lhs.recipeID == rhs.recipeID &&
        lhs.correlationID == rhs.correlationID &&
        lhs.transactionID == rhs.transactionID &&
        lhs.stockRowID == rhs.stockRowID &&
        lhs.storeID == rhs.storeID &&
        lhs.userID == rhs.userID &&
        lhs.note == rhs.note &&
        lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias StockJournal = [StockJournalEntry]
