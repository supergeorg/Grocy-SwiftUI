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
    let inputRequired: Bool
    let defaultValue: String?
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
        case inputRequired = "input_required"
        case defaultValue = "default_value"
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
            self.inputRequired = try container.decodeFlexibleBoolIfPresent(forKey: .inputRequired) ?? false
            self.defaultValue = try? container.decodeIfPresent(String.self, forKey: .defaultValue) ?? nil
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
        inputRequired: Bool = false,
        defaultValue: String? = nil,
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
        self.inputRequired = inputRequired
        self.defaultValue = defaultValue
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

extension MDUserField {
    /// The file group of file and picture userfields.
    static let fileGroup = "userfiles"

    var fieldType: UserFieldType? { UserFieldType(rawValue: type) }

    /// The options of a select list, one per line of `config`.
    var options: [String] {
        (config ?? "").split(whereSeparator: \.isNewline).map(String.init)
    }

    /// A saved value as text for lists. Checkboxes are a check mark, links with a title their title, files their name.
    func displayValue(_ value: String) -> String {
        switch fieldType {
        case .checkbox:
            return value == "1" ? "✓" : ""
        case .linkWithTitle:
            let link = try? JSONDecoder().decode([String: String].self, from: Data(value.utf8))
            return link?["title"].flatMap { $0.isEmpty ? nil : $0 } ?? link?["link"] ?? value
        case .file, .image:
            return Self.fileName(of: value)
        default:
            return value
        }
    }

    /// Grocy stores files as `base64(stored name)_base64(file name)`. This is the file name.
    static func fileName(of value: String) -> String {
        guard let encodedName = value.split(separator: "_").last, let data = Data(base64Encoded: String(encodedName)) else { return value }
        return String(data: data, encoding: .utf8) ?? value
    }

    /// The stored file's name in the file group `userfiles`, base64-encoded as the files API expects it.
    static func encodedStoredFileName(of value: String) -> String? {
        guard let encodedName = value.split(separator: "_").first, !encodedName.isEmpty else { return nil }
        return String(encodedName)
    }
}

typealias MDUserFields = [MDUserField]

/// The userfield values of one object (`/userfields/{entity}/{objectId}`), by field name. Unset fields are missing.
/// Grocy stores every value as text, see `UserFieldType` for the formats.
struct UserfieldValues: Codable, Equatable {
    var values: [String: String]

    init(_ values: [String: String] = [:]) {
        self.values = values
    }

    init(from decoder: Decoder) throws {
        // An entity without userfields comes back as an empty JSON array.
        let values = try? decoder.singleValueContainer().decode([String: String?].self)
        self.values = values?.compactMapValues { $0 } ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
}

/// What a form changed in the userfields of an object, saved with `GrocyViewModel.saveUserfields` after the object.
/// Like Grocy's web form, only edited fields are sent, and files are uploaded (and replaced ones deleted) only on save.
struct UserfieldChanges: Equatable {
    /// The edited values by field name.
    var values: [String: String] = [:]
    /// New files by their encoded stored name, uploaded to `userfiles` on save.
    var uploads: [String: Data] = [:]
    /// Encoded stored names of saved files that were replaced or removed, deleted after saving.
    var obsoleteFiles: Set<String> = []

    /// Sets a new file as the value of a file or picture field. `savedValue` is the field's value on the server.
    mutating func setFile(_ data: Data, named fileName: String, for field: String, savedValue: String?) {
        let storedName = "\(UUID().uuidString).\((fileName as NSString).pathExtension.isEmpty ? "bin" : (fileName as NSString).pathExtension)"
        let encodedStoredName = Data(storedName.utf8).base64EncodedString()
        removeFile(of: field, savedValue: savedValue)
        uploads[encodedStoredName] = data
        values[field] = "\(encodedStoredName)_\(Data(fileName.utf8).base64EncodedString())"
    }

    /// Removes the file of a file or picture field.
    mutating func removeFile(of field: String, savedValue: String?) {
        if let pending = values[field].flatMap(MDUserField.encodedStoredFileName) {
            uploads[pending] = nil
        }
        if let saved = savedValue.flatMap(MDUserField.encodedStoredFileName) {
            obsoleteFiles.insert(saved)
        }
        values[field] = ""
    }
}

/// The value formats: checkboxes are `"1"`/`"0"`, dates `yyyy-MM-dd` (and `HH:mm:ss`), checklists comma-separated options,
/// links with a title `{"title": …, "link": …}`, files and images `base64(stored name)_base64(file name)`.
enum UserFieldType: String, CaseIterable {
    case none = ""
    case textSingleLine = "text-single-line"
    case textMultiLine = "text-multi-line"
    case numberIntegral = "number-integral"
    case numberDezimal = "number-decimal"
    case numberCurrency = "number-currency"
    case date
    case dateTime = "datetime"
    case checkbox
    case presetList = "preset-list"
    case presetChecklist = "preset-checklist"
    case link
    case linkWithTitle = "link-with-title"
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
        case .numberCurrency:
            return "Number (currency)"
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
        case .linkWithTitle:
            return "Link (with title)"
        case .file:
            return "File"
        case .image:
            return "Image"
        }
    }
}
