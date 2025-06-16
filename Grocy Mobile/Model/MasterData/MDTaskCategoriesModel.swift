//
//  MDTaskCategoriesModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 12.03.21.
//

import Foundation

// MARK: - MDTaskCategory

struct MDTaskCategory: Codable {
    let id: Int
    let name: String
    let mdTaskCategoryDescription: String?
    let rowCreatedTimestamp: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case mdTaskCategoryDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            self.name = try container.decode(String.self, forKey: .name)
            self.mdTaskCategoryDescription = try? container.decodeIfPresent(String.self, forKey: .mdTaskCategoryDescription) ?? nil
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int,
        name: String,
        mdTaskCategoryDescription: String? = nil,
        rowCreatedTimestamp: String
    ) {
        self.id = id
        self.name = name
        self.mdTaskCategoryDescription = mdTaskCategoryDescription
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias MDTaskCategories = [MDTaskCategory]
