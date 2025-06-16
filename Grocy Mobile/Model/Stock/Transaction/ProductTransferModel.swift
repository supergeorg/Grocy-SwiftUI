//
//  ProductTransferModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 25.11.20.
//

// amount    number
// The amount to transfer - please note that when tare weight handling for the product is enabled, this needs to be the amount including the container weight (gross), the amount to be posted will be automatically calculated based on what is in stock and the defined tare weight

// location_id_from    number($integer)
// A valid location id, the location from where the product should be transfered

// location_id_to    number($integer)
// A valid location id, the location to where the product should be transfered

// stock_entry_id    string
// A specific stock entry id to transfer, if used, the amount has to be 1

import Foundation

// MARK: - ProductTransfer

struct ProductTransfer: Codable {
    let amount: Double
    let locationIDFrom, locationIDTo: Int
    let stockEntryID: String?

    enum CodingKeys: String, CodingKey {
        case amount
        case locationIDFrom = "location_id_from"
        case locationIDTo = "location_id_to"
        case stockEntryID = "stock_entry_id"
    }
}
