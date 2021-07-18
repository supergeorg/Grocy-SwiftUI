//
//  MDUserFieldModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 11.12.20.
//

import Foundation

// MARK: - MDUserField
struct MDUserField: Codable {
    let id: Int
    let entity, name, caption, type: String
    let showAsColumnInTables: Int
    let rowCreatedTimestamp: String
    let config: String?
    let sortNumber: SortNumber

    enum CodingKeys: String, CodingKey {
        case id, entity, name, caption, type
        case showAsColumnInTables = "show_as_column_in_tables"
        case rowCreatedTimestamp = "row_created_timestamp"
        case config
        case sortNumber = "sort_number"
    }
}

typealias MDUserFields = [MDUserField]

enum SortNumber: Codable {
    case integer(Int)
    case string(String)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }
        throw DecodingError.typeMismatch(SortNumber.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for SortNumber"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}


enum UserFieldType: String, CaseIterable {
    case none = ""
    case textSingleLine = "text-single-line"
    case textMultiLine = "text-multi-line"
    case numberIntegral = "number-integral"
    case numberDezimal = "number-decimal"
    case date = "date"
    case dateTime = "datetime"
    case checkbox = "checkbox"
    case presetList = "preset-list"
    case presetChecklist = "preset-checklist"
    case link = "link"
    case file = "file"
    case image = "image"
    
    func getDescription() -> String {
        switch self {
        case .none:
            return ""
        case .textSingleLine:
            return "str.md.userField.type.textSingleLine"
        case .textMultiLine:
            return "str.md.userField.type.textMultiLine"
        case .numberIntegral:
            return "str.md.userField.type.numberIntegral"
        case .numberDezimal:
            return "str.md.userField.type.numberDezimal"
        case .date:
            return "str.md.userField.type.date"
        case .dateTime:
            return "str.md.userField.type.dateTime"
        case .checkbox:
            return "str.md.userField.type.checkbox"
        case .presetList:
            return "str.md.userField.type.presetList"
        case .presetChecklist:
            return "str.md.userField.type.presetChecklist"
        case .link:
            return "str.md.userField.type.link"
        case .file:
            return "str.md.userField.type.file"
        case .image:
            return "str.md.userField.type.image"
        }
    }
}
