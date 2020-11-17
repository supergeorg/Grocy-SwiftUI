//
//  ProductOpenModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 27.10.20.
//

//amount    number
//The amount to mark as opened

//stock_entry_id    string
//A specific stock entry id to open, if used, the amount has to be 1

import Foundation

struct ProductOpen: Codable {
    let amount: Int
    let stockEntryID: String?

    enum CodingKeys: String, CodingKey {
        case amount
        case stockEntryID = "stock_entry_id"
    }
}
