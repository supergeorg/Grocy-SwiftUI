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
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.productID = try container.decode(Int.self, forKey: .productID)
        do {
            self.barcode = try String(container.decode(Int.self, forKey: .barcode))
        } catch DecodingError.typeMismatch {
            self.barcode = try container.decode(String.self, forKey: .barcode)
        }
        self.quID = try? container.decodeIfPresent(Int.self, forKey: .quID)
        self.amount = try? container.decodeIfPresent(Double.self, forKey: .amount)
        self.shoppingLocationID = try? container.decodeIfPresent(Int.self, forKey: .shoppingLocationID)
        self.lastPrice = try? container.decodeIfPresent(Double.self, forKey: .lastPrice)
        self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        self.note = try? container.decodeIfPresent(String.self, forKey: .note)
    }
    
    init(id: Int,
        productID: Int,
        barcode: String,
        quID: Int? = nil,
        amount: Double? = nil,
        shoppingLocationID: Int? = nil,
        lastPrice: Double? = nil,
        rowCreatedTimestamp: String,
        note: String? = nil) {
            self.id = id
            self.productID = productID
            self.barcode = String(barcode)
            self.quID = quID
            self.amount = amount
            self.shoppingLocationID = shoppingLocationID
            self.lastPrice = lastPrice
            self.rowCreatedTimestamp = rowCreatedTimestamp
            self.note = note

    }
}

typealias MDProductBarcodes = [MDProductBarcode]
