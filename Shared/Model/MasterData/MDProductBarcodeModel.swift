//
//  MDProductBarcodeModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 25.11.20.
//

import Foundation

// MARK: - MDProductBarcode
struct MDProductBarcode: Codable {
    let id, productID: Int
    let barcode: String
    let quID: Int?
    let amount: Double?
    let shoppingLocationID: Int?
    let lastPrice: Double?
    let rowCreatedTimestamp: String
    let note: String?
//    let userfields: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case barcode
        case quID = "qu_id"
        case amount
        case shoppingLocationID = "shopping_location_id"
        case lastPrice = "last_price"
        case rowCreatedTimestamp = "row_created_timestamp"
        case note
//        case userfields
    }
}

typealias MDProductBarcodes = [MDProductBarcode]
