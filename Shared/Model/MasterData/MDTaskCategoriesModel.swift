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
//    let userfields: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id, name
        case mdTaskCategoryDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
//        case userfields
    }
}

typealias MDTaskCategories = [MDTaskCategory]
