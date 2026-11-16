//
//  MDEquipmentModel.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import Foundation
import SwiftData

/// A piece of equipment (`/objects/equipment`) with notes (HTML) and an optional instruction manual
/// (a PDF in the `equipmentmanuals` file group).
@Model
class MDEquipment: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var name: String
    /// HTML, edited with the rich text editor. Called "Notes" in the Grocy web app.
    var mdEquipmentDescription: String
    var instructionManualFileName: String?
    var rowCreatedTimestamp: Date

    /// File group of the instruction manuals on the server.
    static let instructionManualGroup = "equipmentmanuals"

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case mdEquipmentDescription = "description"
        case instructionManualFileName = "instruction_manual_file_name"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.mdEquipmentDescription = try container.decodeIfPresent(String.self, forKey: .mdEquipmentDescription) ?? ""
            let fileName = try container.decodeIfPresent(String.self, forKey: .instructionManualFileName)
            self.instructionManualFileName = (fileName?.isEmpty ?? true) ? nil : fileName
            self.rowCreatedTimestamp = getDateFromString(try container.decodeIfPresent(String.self, forKey: .rowCreatedTimestamp)) ?? Date()
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(mdEquipmentDescription, forKey: .mdEquipmentDescription)
        try container.encode(instructionManualFileName, forKey: .instructionManualFileName)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    init(
        id: Int = -1,
        name: String = "",
        mdEquipmentDescription: String = "",
        instructionManualFileName: String? = nil,
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.mdEquipmentDescription = mdEquipmentDescription
        self.instructionManualFileName = instructionManualFileName
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    static func == (lhs: MDEquipment, rhs: MDEquipment) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.mdEquipmentDescription == rhs.mdEquipmentDescription && lhs.instructionManualFileName == rhs.instructionManualFileName
            && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias MDEquipments = [MDEquipment]
