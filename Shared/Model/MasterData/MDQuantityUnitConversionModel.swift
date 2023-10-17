//
//  MDQuantityUnitConversionModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 08.10.21.
//

import Foundation
import SwiftData

@Model
class MDQuantityUnitConversion: Codable {
    @Attribute(.unique) var id: Int
    var fromQuID: Int
    var toQuID: Int
    var factor: Double
    var productID: Int?
    var rowCreatedTimestamp: String

    enum CodingKeys: String, CodingKey {
        case id
        case fromQuID = "from_qu_id"
        case toQuID = "to_qu_id"
        case factor
        case productID = "product_id"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            do { self.fromQuID = try container.decode(Int.self, forKey: .fromQuID) } catch { self.fromQuID = Int(try container.decode(String.self, forKey: .fromQuID))! }
            do { self.toQuID = try container.decode(Int.self, forKey: .toQuID) } catch { self.toQuID = Int(try container.decode(String.self, forKey: .toQuID))! }
            do { self.factor = try container.decode(Double.self, forKey: .factor) } catch { self.factor = Double(try container.decode(String.self, forKey: .factor))! }
            do { self.productID = try container.decodeIfPresent(Int.self, forKey: .productID) } catch { self.productID = try? Int(container.decodeIfPresent(String.self, forKey: .productID) ?? "") }
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fromQuID, forKey: .fromQuID)
        try container.encode(toQuID, forKey: .toQuID)
        try container.encode(factor, forKey: .factor)
        try container.encode(productID, forKey: .productID)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    init(
        id: Int,
        fromQuID: Int,
        toQuID: Int,
        factor: Double,
        productID: Int?,
        rowCreatedTimestamp: String
    ) {
        self.id = id
        self.fromQuID = fromQuID
        self.toQuID = toQuID
        self.factor = factor
        self.productID = productID
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias MDQuantityUnitConversions = [MDQuantityUnitConversion]
