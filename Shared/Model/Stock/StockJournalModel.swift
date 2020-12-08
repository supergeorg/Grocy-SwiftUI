//
//  StockJournalModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

//correlation_id    string
//undone    integer
//undone_timestamp    string($date-time)
//amount    number($float)
//location_id    integer
//location_name    string
//product_name    string
//qu_name    string
//qu_name_plural    string
//user_display_name    string
//spoiled    boolean
//default: false
//transaction_type    stringEnum:
//[ purchase, consume, inventory-correction, product-opened ]
//row_created_timestamp    string($date-time)

import Foundation

struct StockJournalEntry: Codable {
    let id: String
    let productID: String
    let amount: String
    let bestBeforeDate: String
    let purchasedDate: String?
    let usedDate: String?
    let spoiled: String
    let stockID: String
    let transactionType: TransactionType
    let price: String
    let undone: String
    let undoneTimestamp: String?
    let openedDate: String?
    let rowCreatedTimestamp: String
    let locationID: String
    let recipeID: String?
    let correlationID: String?
    let transactionID: String
    let stockRowID: String?
    let shoppingLocationID: String?
    let userID: String
    let userfields: String?
    
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
        case userfields
    }
}

typealias StockJournal = [StockJournalEntry]
