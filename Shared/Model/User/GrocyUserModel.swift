//
//  GrocyUserModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import Foundation

// MARK: - GrocyUser
struct GrocyUser: Codable {
    let id, username: String
    let firstName, lastName: String?
    let rowCreatedTimestamp, displayName: String

    enum CodingKeys: String, CodingKey {
        case id, username
        case firstName = "first_name"
        case lastName = "last_name"
        case rowCreatedTimestamp = "row_created_timestamp"
        case displayName = "display_name"
    }
}

typealias GrocyUsers = [GrocyUser]
