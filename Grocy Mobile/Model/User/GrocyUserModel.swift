//
//  GrocyUserModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import Foundation
import SwiftData

@Model
class GrocyUser: Codable {
    @Attribute(.unique) var id: Int
    var username: String
    var firstName: String?
    var lastName: String?
    var displayName: String
    var pictureFileName: String?
    var rowCreatedTimestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id, username
        case firstName = "first_name"
        case lastName = "last_name"
        case rowCreatedTimestamp = "row_created_timestamp"
        case displayName = "display_name"
        case pictureFileName = "picture_file_name"
    }
    
    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            self.username = try container.decode(String.self, forKey: .username)
            self.firstName = try? container.decodeIfPresent(String.self, forKey: .firstName)
            self.lastName = try? container.decodeIfPresent(String.self, forKey: .lastName)
            self.displayName = try container.decode(String.self, forKey: .displayName)
            self.pictureFileName = try? container.decodeIfPresent(String.self, forKey: .pictureFileName)
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
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
