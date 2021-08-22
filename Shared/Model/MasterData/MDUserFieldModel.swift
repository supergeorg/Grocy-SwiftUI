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
    let name: String
    let entity: String
    let caption: String
    let type: String
    let showAsColumnInTables: Int
    let config: String?
    let sortNumber: Int?
    let rowCreatedTimestamp: String
    
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
    
    //    Decoder with Numbers instead of strings
    //    init(from decoder: Decoder) throws {
    //        let container = try decoder.container(keyedBy: CodingKeys.self)
    //        self.id = try container.decode(Int.self, forKey: .id)
    //        self.name = try container.decode(String.self, forKey: .name)
    //        self.entity = try container.decode(String.self, forKey: .entity)
    //        self.caption = try container.decode(String.self, forKey: .caption)
    //        self.type = try container.decode(String.self, forKey: .type)
    //        self.showAsColumnInTables = try container.decode(Int.self, forKey: .showAsColumnInTables)
    //        self.config = try? container.decodeIfPresent(String.self, forKey: .config) ?? nil
    //        self.sortNumber = try? container.decodeIfPresent(Int.self, forKey: .sortNumber) ?? nil
    //        self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
    //    }
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try Int(container.decode(String.self, forKey: .id))!
            self.name = try container.decode(String.self, forKey: .name)
            self.entity = try container.decode(String.self, forKey: .entity)
            self.caption = try container.decode(String.self, forKey: .caption)
            self.type = try container.decode(String.self, forKey: .type)
            self.showAsColumnInTables = try Int(container.decode(String.self, forKey: .showAsColumnInTables)) ?? 0
            self.config = try? container.decodeIfPresent(String.self, forKey: .config) ?? nil
            self.sortNumber = try? Int(container.decodeIfPresent(String.self, forKey: .sortNumber) ?? "")
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    init(id: Int,
         name: String,
         entity: String,
         caption: String,
         type: String,
         showAsColumnInTables: Int,
         config: String? = nil,
         sortNumber: Int? = nil,
         rowCreatedTimestamp: String) {
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
