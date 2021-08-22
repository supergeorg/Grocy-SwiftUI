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
    let firstName: String?
    let lastName: String?
    let displayName: String
    let pictureFileName: String?
    let rowCreatedTimestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id, username
        case firstName = "first_name"
        case lastName = "last_name"
        case rowCreatedTimestamp = "row_created_timestamp"
        case displayName = "display_name"
        case pictureFileName = "picture_file_name"
    }
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            //            self.id = try container.decode(Int.self, forKey: .id)
            self.id = try Int(container.decode(String.self, forKey: .id))!
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
