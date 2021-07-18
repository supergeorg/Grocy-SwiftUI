//
//  GrocyUserModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import Foundation

// MARK: - GrocyUser
struct GrocyUser: Codable {
    let id: Int
    let username: String
    let firstName, lastName: String?
    let rowCreatedTimestamp, displayName: String
    let pictureFileName: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case firstName = "first_name"
        case lastName = "last_name"
        case rowCreatedTimestamp = "row_created_timestamp"
        case displayName = "display_name"
        case pictureFileName = "picture_file_name"
    }
}

typealias GrocyUsers = [GrocyUser]

// MARK: - GrocyUserPOST
struct GrocyUserPOST: Codable {
    let id: Int
    let username, firstName, lastName, password: String
    let rowCreatedTimestamp: String

    enum CodingKeys: String, CodingKey {
        case id, username
        case firstName = "first_name"
        case lastName = "last_name"
        case password
        case rowCreatedTimestamp = "row_created_timestamp"
    }
}
