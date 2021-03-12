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
    let userfields: [String: String]?
    
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
