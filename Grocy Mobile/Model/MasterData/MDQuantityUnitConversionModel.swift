//
//  MDQuantityUnitConversionModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 08.10.21.
//

import Foundation
import SwiftData

@Model
class MDQuantityUnitConversion: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var fromQuID: Int
    var toQuID: Int
    var factor: Double
    var productID: Int?
    var rowCreatedTimestamp: Date

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
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.fromQuID = try container.decodeFlexibleInt(forKey: .fromQuID)
            self.toQuID = try container.decodeFlexibleInt(forKey: .toQuID)
            self.factor = try container.decodeFlexibleDouble(forKey: .factor)
            self.productID = try container.decodeFlexibleIntIfPresent(forKey: .productID)
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp)) ?? .distantPast
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
        id: Int = -1,
        fromQuID: Int = -1,
        toQuID: Int = -1,
        factor: Double = 1.0,
        productID: Int? = nil,
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.fromQuID = fromQuID
        self.toQuID = toQuID
        self.factor = factor
        self.productID = productID
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    static func == (lhs: MDQuantityUnitConversion, rhs: MDQuantityUnitConversion) -> Bool {
        lhs.id == rhs.id && lhs.fromQuID == rhs.fromQuID && lhs.toQuID == rhs.toQuID && lhs.factor == rhs.factor && lhs.productID == rhs.productID
            && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias MDQuantityUnitConversions = [MDQuantityUnitConversion]
