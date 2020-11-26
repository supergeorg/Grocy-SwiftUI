//
//  MDProductBarcodeModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 25.11.20.
//

import Foundation

// MARK: - ProductBarcode
struct MDProductBarcode: Codable {
    let id, productID, barcode, quID: String
    let shoppingLocationID, amount: String

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case barcode
        case quID = "qu_id"
        case shoppingLocationID = "shopping_location_id"
        case amount
    }
}
