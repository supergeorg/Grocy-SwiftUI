//
//  MDQuantityUnitsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

// MARK: - MDQuantityUnit
struct MDQuantityUnit: Codable {
    let id, name: String
    let mdQuantityUnitDescription: String?
    let rowCreatedTimestamp, namePlural: String
    let pluralForms, userfields: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case mdQuantityUnitDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
        case namePlural = "name_plural"
        case pluralForms = "plural_forms"
        case userfields
    }
}

typealias MDQuantityUnits = [MDQuantityUnit]

struct MDQuantityUnitPOST: Codable {
    let id: Int
    let name, mdQuantityUnitDescription, rowCreatedTimestamp: String
    let namePlural: String
    let pluralForms, userfields: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case mdQuantityUnitDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
        case namePlural = "name_plural"
        case pluralForms = "plural_forms"
        case userfields
    }
}
