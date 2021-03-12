//
//  MDProductGroupsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

// MARK: - MDProductGroup
struct MDProductGroup: Codable {
    let id, name: String
    let mdProductGroupDescription: String?
    let rowCreatedTimestamp: String
    let userfields: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case mdProductGroupDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
        case userfields
    }
}

typealias MDProductGroups = [MDProductGroup]
