//
//  MDProductBarcodeModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 25.11.20.
//

import Foundation
import SwiftData

@Model
class MDProductBarcode: Codable, Equatable, Identifiable, CustomStringConvertible {
    @Attribute(.unique) var id: Int
    var productID: Int
    var barcode: String
    var quID: Int?
    var amount: Double?
    var storeID: Int?
    var lastPrice: Double?
    var note: String
    var rowCreatedTimestamp: Date

    var description: String {
        return """
            MDProductBarcode(id: \(id), 
                    productID: \(productID), 
                    barcode: \(barcode), 
                    quID: \(quID, default: "?"), 
                    amount: \(amount, default: "?"), 
                    storeID: \(storeID, default: "?"), 
                    lastPrice: \(lastPrice, default: "?"), 
                    note: \(note), 
                    created: \(rowCreatedTimestamp))
            """
    }

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case barcode
        case quID = "qu_id"
        case amount
        case storeID = "shopping_location_id"
        case lastPrice = "last_price"
        case rowCreatedTimestamp = "row_created_timestamp"
        case note
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.productID = try container.decodeFlexibleInt(forKey: .productID)
            self.barcode = try container.decodeFlexibleString(forKey: .barcode)
            self.quID = try container.decodeFlexibleIntIfPresent(forKey: .quID)
            self.amount = try container.decodeFlexibleDoubleIfPresent(forKey: .amount)
            self.storeID = try container.decodeFlexibleIntIfPresent(forKey: .storeID)
            self.lastPrice = try container.decodeFlexibleDoubleIfPresent(forKey: .lastPrice)
            self.note = (try? container.decodeIfPresent(String.self, forKey: .note)) ?? ""
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp)) ?? .distantPast
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(productID, forKey: .productID)
        try container.encode(barcode, forKey: .barcode)
        try container.encode(quID, forKey: .quID)
        try container.encode(amount, forKey: .amount)
        try container.encode(storeID, forKey: .storeID)
        try container.encode(lastPrice, forKey: .lastPrice)
        try container.encode(note, forKey: .note)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    init(
        id: Int = -1,
        productID: Int = -1,
        barcode: String = "",
        quID: Int? = nil,
        amount: Double? = nil,
        storeID: Int? = nil,
        lastPrice: Double? = nil,
        note: String = "",
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.productID = productID
        self.barcode = barcode
        self.quID = quID
        self.amount = amount
        self.storeID = storeID
        self.lastPrice = lastPrice
        self.note = note
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    static func == (lhs: MDProductBarcode, rhs: MDProductBarcode) -> Bool {
        lhs.id == rhs.id && lhs.productID == rhs.productID && lhs.barcode == rhs.barcode && lhs.quID == rhs.quID && lhs.amount == rhs.amount
            && lhs.storeID == rhs.storeID && lhs.lastPrice == rhs.lastPrice && lhs.note == rhs.note
            && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias MDProductBarcodes = [MDProductBarcode]
