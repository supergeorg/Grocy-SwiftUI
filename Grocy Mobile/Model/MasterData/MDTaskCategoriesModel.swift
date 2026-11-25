//
//  MDTaskCategoriesModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 12.03.21.
//

import Foundation
import SwiftData

@Model
class MDTaskCategory: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var name: String
    var active: Bool
    var mdTaskCategoryDescription: String
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case active
        case mdTaskCategoryDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.active = try container.decodeFlexibleBool(forKey: .active)
            self.mdTaskCategoryDescription = (try? container.decodeIfPresent(String.self, forKey: .mdTaskCategoryDescription)) ?? ""
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
        try container.encode(mdTaskCategoryDescription, forKey: .mdTaskCategoryDescription)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    init(
        id: Int = -1,
        name: String = "",
        active: Bool = true,
        mdTaskCategoryDescription: String = "",
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.active = active
        self.mdTaskCategoryDescription = mdTaskCategoryDescription
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias MDTaskCategories = [MDTaskCategory]
