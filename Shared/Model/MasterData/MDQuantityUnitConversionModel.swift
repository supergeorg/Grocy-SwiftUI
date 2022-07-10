//
//  MDQuantityUnitConversionModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 08.10.21.
//

import Foundation

// MARK: - MDQuantityUnitConversion

struct MDQuantityUnitConversion: Codable {
    let id: Int
    let fromQuID: Int
    let toQuID: Int
    let factor: Double
    let productID: Int?
    let rowCreatedTimestamp: String

    enum CodingKeys: String, CodingKey {
        case id
        case fromQuID = "from_qu_id"
        case toQuID = "to_qu_id"
        case factor
        case productID = "product_id"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    init(from decoder: Decoder) throws {
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
