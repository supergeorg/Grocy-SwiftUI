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
    let storeID: Int?
    let lastPrice: Double?
    let rowCreatedTimestamp: String
    let note: String?

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

    init(from decoder: Decoder) throws {
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
            self.note = try? container.decodeIfPresent(String.self, forKey: .note)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int,
        productID: Int,
        barcode: String,
        quID: Int? = nil,
        amount: Double? = nil,
        storeID: Int? = nil,
        lastPrice: Double? = nil,
        rowCreatedTimestamp: String,
        note: String? = nil
    ) {
        self.id = id
        self.productID = productID
        self.barcode = String(barcode)
        self.quID = quID
        self.amount = amount
        self.storeID = storeID
        self.lastPrice = lastPrice
        self.rowCreatedTimestamp = rowCreatedTimestamp
        self.note = note
    }
}

typealias MDProductBarcodes = [MDProductBarcode]
