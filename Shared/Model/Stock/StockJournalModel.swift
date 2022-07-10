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
    let bestBeforeDate: String?
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
    let note: String?

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
        case note
    }

    init(from decoder: Decoder) throws {
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
            do { self.shoppingLocationID = try container.decodeIfPresent(Int.self, forKey: .shoppingLocationID) } catch { self.shoppingLocationID = try? Int(container.decodeIfPresent(String.self, forKey: .shoppingLocationID) ?? "") }
            do { self.userID = try container.decode(Int.self, forKey: .userID) } catch { self.userID = try Int(container.decode(String.self, forKey: .userID))! }
            self.note = try? container.decodeIfPresent(String.self, forKey: .note)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
}

typealias StockJournal = [StockJournalEntry]
