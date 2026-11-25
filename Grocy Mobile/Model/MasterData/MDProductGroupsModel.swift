//
//  MDProductGroupsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation
import SwiftData

@Model
class MDProductGroup: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var name: String
    var active: Bool
    var mdProductGroupDescription: String
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case active
        case mdProductGroupDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.active = try container.decodeFlexibleBool(forKey: .active)
            self.mdProductGroupDescription = (try? container.decodeIfPresent(String.self, forKey: .mdProductGroupDescription)) ?? ""
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp)) ?? .distantPast
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(active, forKey: .active)
        try container.encode(mdProductGroupDescription, forKey: .mdProductGroupDescription)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    init(
        id: Int = -1,
        name: String = "",
        active: Bool = true,
        mdProductGroupDescription: String = "",
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.active = active
        self.mdProductGroupDescription = mdProductGroupDescription
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    static func == (lhs: MDProductGroup, rhs: MDProductGroup) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.active == rhs.active && lhs.mdProductGroupDescription == rhs.mdProductGroupDescription
            && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias MDProductGroups = [MDProductGroup]
