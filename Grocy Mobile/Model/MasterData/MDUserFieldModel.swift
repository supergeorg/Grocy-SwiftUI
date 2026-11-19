//
//  MDUserFieldModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 11.12.20.
//

import Foundation

// MARK: - MDUserField

/// A custom field of an entity (`/objects/userfields`). Only kept in memory, not in SwiftData.
struct MDUserField: Codable, Equatable, Identifiable {
    let id: Int
    let name: String
    let entity: String
    let caption: String
    let type: String
    let showAsColumnInTables: Bool
    let config: String?
    let sortNumber: Int?
    let rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case entity
        case caption
        case type
        case showAsColumnInTables = "show_as_column_in_tables"
        case config
        case sortNumber = "sort_number"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.entity = try container.decode(String.self, forKey: .entity)
            self.caption = try container.decode(String.self, forKey: .caption)
            self.type = try container.decode(String.self, forKey: .type)
            self.showAsColumnInTables = try container.decodeFlexibleBool(forKey: .showAsColumnInTables)
            self.config = try? container.decodeIfPresent(String.self, forKey: .config) ?? nil
            self.sortNumber = try container.decodeFlexibleIntIfPresent(forKey: .sortNumber)
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp)) ?? Date()
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int,
        name: String,
        entity: String,
        caption: String,
        type: String,
        showAsColumnInTables: Bool,
        config: String? = nil,
        sortNumber: Int? = nil,
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.entity = entity
        self.caption = caption
        self.type = type
        self.showAsColumnInTables = showAsColumnInTables
        self.config = config
        self.sortNumber = sortNumber
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias MDUserFields = [MDUserField]

enum UserFieldType: String, CaseIterable {
    case none = ""
    case textSingleLine = "text-single-line"
    case textMultiLine = "text-multi-line"
    case numberIntegral = "number-integral"
    case numberDezimal = "number-decimal"
    case date
    case dateTime = "datetime"
    case checkbox
    case presetList = "preset-list"
    case presetChecklist = "preset-checklist"
    case link
    case file
    case image

    func getDescription() -> String {
        switch self {
        case .none:
            return ""
        case .textSingleLine:
            return "Text (single line)"
        case .textMultiLine:
            return "Text (multi line)"
        case .numberIntegral:
            return "Number (integral)"
        case .numberDezimal:
            return "Number (decimal)"
        case .date:
            return "Date (without time)"
        case .dateTime:
            return "Date & time"
        case .checkbox:
            return "Checkbox"
        case .presetList:
            return "Select list (a single item can be selected)"
        case .presetChecklist:
            return "Select list (multiple items can be selected)"
        case .link:
            return "Link"
        case .file:
            return "File"
        case .image:
            return "Image"
        }
    }
}
