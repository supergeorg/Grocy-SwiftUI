//
//  MDLocationsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation
import SwiftData

@Model
class MDLocation: Codable, Equatable, Identifiable, CustomStringConvertible {
    @Attribute(.unique) var id: Int
    var name: String
    var active: Bool
    var mdLocationDescription: String
    var isFreezer: Bool
    var rowCreatedTimestamp: Date

    var description: String {
        return """
            Location(id: \(id), 
                    name: \(name), 
                    active: \(active), 
                    description: \(mdLocationDescription), 
                    isFreezer: \(isFreezer), 
                    created: \(rowCreatedTimestamp))
            """
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case active
        case mdLocationDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
        case isFreezer = "is_freezer"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.active = try container.decodeFlexibleBool(forKey: .active)
            self.mdLocationDescription = (try? container.decodeIfPresent(String.self, forKey: .mdLocationDescription)) ?? ""
            self.isFreezer = try container.decodeFlexibleBool(forKey: .isFreezer)
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp))!
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(active, forKey: .active)
        try container.encode(mdLocationDescription, forKey: .mdLocationDescription)
        try container.encode(isFreezer, forKey: .isFreezer)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    init(
        id: Int = -1,
        name: String = "",
        active: Bool = true,
        mdLocationDescription: String = "",
        isFreezer: Bool = false,
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.active = active
        self.mdLocationDescription = mdLocationDescription
        self.isFreezer = isFreezer
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    static func == (lhs: MDLocation, rhs: MDLocation) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.active == rhs.active && lhs.mdLocationDescription == rhs.mdLocationDescription
            && lhs.isFreezer == rhs.isFreezer && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias MDLocations = [MDLocation]
