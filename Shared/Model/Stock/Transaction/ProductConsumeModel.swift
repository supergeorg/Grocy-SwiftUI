//
//  ProductConsumeModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 27.10.20.
//

import Foundation

//amount    number
//The amount to remove - please note that when tare weight handling for the product is enabled, this needs to be the amount including the container weight (gross), the amount to be posted will be automatically calculated based on what is in stock and the defined tare weight

//transaction_type    string [ purchase, consume, inventory-correction, product-opened ]

//spoiled    boolean
//True when the given product was spoiled, defaults to false

//stock_entry_id    string
//A specific stock entry id to consume, if used, the amount has to be 1

//recipe_id    number($integer)
//A valid recipe id for which this product was used (for statistical purposes only)

//location_id    number($integer)
//A valid location id (if supplied, only stock at the given location is considered, if ommitted, stock of any location is considered)

//exact_amount    boolean
//For tare weight handling enabled products, true when the given is the absolute amount to be consumed, not the amount including the container weight

//allow_subproduct_substitution    boolean
//True when any in-stock sub product should be used when the given product is a parent product and currently not in-stock

struct ProductConsume: Codable {
    let amount: Double
    let transactionType: TransactionType
    let spoiled: Bool
    let stockEntryID: String?
    let recipeID: Int?
    let locationID: Int?
    let exactAmount: Bool?
    let allowSubproductSubstitution: Bool?

    enum CodingKeys: String, CodingKey {
        case amount
        case transactionType = "transaction_type"
        case spoiled
        case stockEntryID = "stock_entry_id"
        case recipeID = "recipe_id"
        case locationID = "location_id"
        case exactAmount = "exact_amount"
        case allowSubproductSubstitution = "allow_subproduct_substitution"
    }
}
