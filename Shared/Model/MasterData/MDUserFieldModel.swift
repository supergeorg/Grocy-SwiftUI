//
//  MDUserFieldModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 11.12.20.
//

import Foundation

// MARK: - MDUserField
struct MDUserField: Codable {
    let id, entity, name, caption: String
    let type, showAsColumnInTables, rowCreatedTimestamp: String
    let config, sortNumber: String?
    let userfields: String?

    enum CodingKeys: String, CodingKey {
        case id, entity, name, caption, type
        case showAsColumnInTables = "show_as_column_in_tables"
        case rowCreatedTimestamp = "row_created_timestamp"
        case config
        case sortNumber = "sort_number"
        case userfields
    }
}

typealias MDUserFields = [MDUserField]
