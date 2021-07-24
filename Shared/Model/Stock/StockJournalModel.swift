//
//  StockJournalModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import Foundation

struct StockJournalEntry: Codable {
    let id: Int
    let productID: Int
    let amount: Double
    let bestBeforeDate: String
    let purchasedDate: String?
    let usedDate: String?
    let spoiled: Int
    let stockID: String
    let transactionType: TransactionType
    let price: Double?
    let undone: Int
    let undoneTimestamp: String?
    let openedDate: String?
    let rowCreatedTimestamp: String
    let locationID: Int
    let recipeID: Int?
    let correlationID: Int?
    let transactionID: String
    let stockRowID: Int?
    let shoppingLocationID: Int?
    let userID: Int
    
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
        case shoppingLocationID = "shopping_location_id"
        case userID = "user_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.productID = try container.decode(Int.self, forKey: .productID)
        self.amount = try container.decode(Double.self, forKey: .amount)
        self.bestBeforeDate = try container.decode(String.self, forKey: .bestBeforeDate)
        self.purchasedDate = try? container.decodeIfPresent(String.self, forKey: .purchasedDate) ?? nil
        self.usedDate = try? container.decodeIfPresent(String.self, forKey: .usedDate) ?? nil
        self.spoiled = try container.decode(Int.self, forKey: .spoiled)
        self.stockID = try container.decode(String.self, forKey: .stockID)
        self.transactionType = try container.decode(TransactionType.self, forKey: .transactionType)
        self.price = try? container.decodeIfPresent(Double.self, forKey: .price) ?? nil
        self.undone = try container.decode(Int.self, forKey: .undone)
        self.undoneTimestamp = try? container.decodeIfPresent(String.self, forKey: .undoneTimestamp) ?? nil
        self.openedDate = try? container.decodeIfPresent(String.self, forKey: .openedDate) ?? nil
        self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        self.locationID = try container.decode(Int.self, forKey: .locationID)
        self.recipeID = try? container.decodeIfPresent(Int.self, forKey: .recipeID) ?? nil
        self.correlationID = try? container.decodeIfPresent(Int.self, forKey: .correlationID) ?? nil
        self.transactionID = try container.decode(String.self, forKey: .transactionID)
        self.stockRowID = try? container.decodeIfPresent(Int.self, forKey: .stockRowID) ?? nil
        self.shoppingLocationID = try? container.decodeIfPresent(Int.self, forKey: .shoppingLocationID) ?? nil
        self.userID = try container.decode(Int.self, forKey: .userID)
    }
}

typealias StockJournal = [StockJournalEntry]
