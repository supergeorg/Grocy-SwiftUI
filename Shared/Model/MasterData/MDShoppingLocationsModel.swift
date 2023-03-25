//
//  MDStoresModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

// MARK: - MDStore

struct MDStore: Codable {
    let id: Int
    let name: String
    let mdStoreDescription: String?
    let rowCreatedTimestamp: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case mdStoreDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            self.name = try container.decode(String.self, forKey: .name)
            self.mdStoreDescription = try? container.decodeIfPresent(String.self, forKey: .mdStoreDescription) ?? nil
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int,
        name: String,
        mdStoreDescription: String? = nil,
        rowCreatedTimestamp: String
    ) {
        self.id = id
        self.name = name
        self.mdStoreDescription = mdStoreDescription
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias MDStores = [MDStore]
