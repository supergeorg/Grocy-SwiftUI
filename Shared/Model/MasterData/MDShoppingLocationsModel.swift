//
//  MDShoppingLocationsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

// MARK: - MDShoppingLocation
struct MDShoppingLocation: Codable {
    let id: Int
    let name: String
    let mdShoppingLocationDescription: String?
    let rowCreatedTimestamp: String
//    let userfields: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id, name
        case mdShoppingLocationDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
//        case userfields
    }
}

typealias MDShoppingLocations = [MDShoppingLocation]
