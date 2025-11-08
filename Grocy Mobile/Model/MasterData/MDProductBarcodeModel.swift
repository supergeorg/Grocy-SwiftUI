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
    var rowCreatedTimestamp: String

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
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            do { self.productID = try container.decode(Int.self, forKey: .productID) } catch { self.productID = try Int(container.decode(String.self, forKey: .productID))! }
            do { self.barcode = try container.decode(String.self, forKey: .barcode) } catch { self.barcode = try String(container.decodeIfPresent(Int.self, forKey: .barcode)!) }
            do { self.quID = try container.decodeIfPresent(Int.self, forKey: .quID) ?? nil } catch { self.quID = try? Int(container.decodeIfPresent(String.self, forKey: .quID) ?? "") }
            do { self.amount = try container.decodeIfPresent(Double.self, forKey: .amount) } catch { self.amount = try Double(container.decodeIfPresent(String.self, forKey: .amount) ?? "") }
            do { self.storeID = try container.decodeIfPresent(Int.self, forKey: .storeID) } catch { self.storeID = try? Int(container.decodeIfPresent(String.self, forKey: .storeID) ?? "") }
            do { self.lastPrice = try container.decodeIfPresent(Double.self, forKey: .lastPrice) } catch { self.lastPrice = try? Double(container.decodeIfPresent(String.self, forKey: .lastPrice) ?? "") }
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
            self.note = (try? container.decodeIfPresent(String.self, forKey: .note)) ?? ""
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
        id: Int,
        productID: Int,
        barcode: String,
        quID: Int? = nil,
        amount: Double? = nil,
        storeID: Int? = nil,
        lastPrice: Double? = nil,
        note: String = "",
        rowCreatedTimestamp: String
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
        lhs.id == rhs.id && lhs.productID == rhs.productID && lhs.barcode == rhs.barcode && lhs.quID == rhs.quID && lhs.amount == rhs.amount && lhs.storeID == rhs.storeID && lhs.lastPrice == rhs.lastPrice && lhs.note == rhs.note
            && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias MDProductBarcodes = [MDProductBarcode]
