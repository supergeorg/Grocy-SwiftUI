//
//  MDProductGroupsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation
import SwiftData

@Model
class MDProductGroup: Codable {
    @Attribute(.unique) var id: Int
    var name: String
    var active: Bool
    var mdProductGroupDescription: String
    var rowCreatedTimestamp: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case active
        case mdProductGroupDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            self.name = try container.decode(String.self, forKey: .name)
            do {
                self.active = try container.decode(Bool.self, forKey: .active)
            } catch {
                do {
                    self.active = try container.decode(Int.self, forKey: .active) == 1
                } catch {
                    self.active = ["1", "true"].contains(try? container.decode(String.self, forKey: .active))
                }
            }
            self.mdProductGroupDescription = (try? container.decodeIfPresent(String.self, forKey: .mdProductGroupDescription)) ?? ""
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
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
        id: Int,
        name: String,
        active: Bool,
        mdProductGroupDescription: String = "",
        rowCreatedTimestamp: String
    ) {
        self.id = id
        self.name = name
        self.active = active
        self.mdProductGroupDescription = mdProductGroupDescription
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias MDProductGroups = [MDProductGroup]
