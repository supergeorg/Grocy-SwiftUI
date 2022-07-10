//
//  ProductOpenModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 27.10.20.
//

// amount    number
// The amount to mark as opened

// stock_entry_id    string
// A specific stock entry id to open, if used, the amount has to be 1

// allow_subproduct_substitution    boolean
// True when any in-stock sub product should be used when the given product is a parent product and currently not in-stock

import Foundation

struct ProductOpen: Codable {
    let amount: Double
    let stockEntryID: String?
    let allowSubproductSubstitution: Bool?

    enum CodingKeys: String, CodingKey {
        case amount
        case stockEntryID = "stock_entry_id"
        case allowSubproductSubstitution = "allow_subproduct_substitution"
    }
}
