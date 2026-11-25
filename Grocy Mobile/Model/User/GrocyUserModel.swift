//
//  GrocyUserModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import Foundation
import SwiftData

@Model
class GrocyUser: Codable, Equatable {
    @Attribute(.unique) var id: Int
    var username: String
    var firstName: String?
    var lastName: String?
    var displayName: String
    var pictureFileName: String?
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case rowCreatedTimestamp = "row_created_timestamp"
        case displayName = "display_name"
        case pictureFileName = "picture_file_name"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.username = try container.decode(String.self, forKey: .username)
            self.firstName = try? container.decodeIfPresent(String.self, forKey: .firstName)
            self.lastName = try? container.decodeIfPresent(String.self, forKey: .lastName)
            self.displayName = try container.decode(String.self, forKey: .displayName)
            self.pictureFileName = try? container.decodeIfPresent(String.self, forKey: .pictureFileName)
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp)) ?? .distantPast
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int = -1,
        username: String = "",
        firstName: String? = nil,
        lastName: String? = nil,
        displayName: String = "",
        pictureFileName: String? = nil,
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.displayName = displayName
        self.pictureFileName = pictureFileName
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(pictureFileName, forKey: .pictureFileName)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    static func == (lhs: GrocyUser, rhs: GrocyUser) -> Bool {
        lhs.id == rhs.id
            && lhs.username == rhs.username
            && lhs.firstName == rhs.firstName
            && lhs.lastName == rhs.lastName
            && lhs.displayName == rhs.displayName
            && lhs.pictureFileName == rhs.pictureFileName
            && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias GrocyUsers = [GrocyUser]

// MARK: - GrocyUserPOST
/// The body to create or edit a user. On edit, Grocy keeps the password when it's empty.
struct GrocyUserPOST: Codable {
    let id: Int
    let username, firstName, lastName, password: String
    /// Grocy sets the picture from this on every edit, so an edit sends the current one to keep it.
    var pictureFileName: String? = nil
    let rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case password
        case pictureFileName = "picture_file_name"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(password, forKey: .password)
        // Sent as `null` too: Grocy reads the key on every create and edit.
        try container.encode(pictureFileName, forKey: .pictureFileName)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }
}
