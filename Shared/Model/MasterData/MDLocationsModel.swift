//
//  MDLocationsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

// MARK: - MDLocation
struct MDLocation: Codable {
    let id, name: String
    let mdLocationDescription: String?
    let rowCreatedTimestamp, isFreezer: String
    let userfields: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case mdLocationDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
        case isFreezer = "is_freezer"
        case userfields
    }
}

typealias MDLocations = [MDLocation]

struct MDLocationPOST: Codable {
    let id: Int
    let name, mdLocationDescription, rowCreatedTimestamp: String
    let isFreezer: String
    let userfields: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case mdLocationDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
        case isFreezer = "is_freezer"
        case userfields
    }
}
