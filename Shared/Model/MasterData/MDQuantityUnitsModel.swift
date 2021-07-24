//
//  MDQuantityUnitsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

// MARK: - MDQuantityUnit
struct MDQuantityUnit: Codable {
    let id: Int
    let name: String
    let namePlural: String
    let mdQuantityUnitDescription: String?
    let rowCreatedTimestamp: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case namePlural = "name_plural"
        case mdQuantityUnitDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.namePlural = try container.decode(String.self, forKey: .namePlural)
        self.mdQuantityUnitDescription = try? container.decodeIfPresent(String.self, forKey: .mdQuantityUnitDescription) ?? nil
        self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
    }
    
    init(id: Int,
         name: String,
         namePlural: String,
         mdQuantityUnitDescription: String? = nil,
         rowCreatedTimestamp: String) {
        self.id = id
        self.name = name
        self.namePlural = namePlural
        self.mdQuantityUnitDescription = mdQuantityUnitDescription
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias MDQuantityUnits = [MDQuantityUnit]
