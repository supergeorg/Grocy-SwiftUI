//
//  MDProductGroupsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

// MARK: - MDProductGroup
struct MDProductGroup: Codable {
    let id: Int
    let name: String
    let mdProductGroupDescription: String?
    let rowCreatedTimestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case mdProductGroupDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
    }
    
    //    Decoder with Numbers instead of strings
    //    init(from decoder: Decoder) throws {
    //        let container = try decoder.container(keyedBy: CodingKeys.self)
    //        self.id = try container.decode(Int.self, forKey: .id)
    //        self.name = try container.decode(String.self, forKey: .name)
    //        self.mdProductGroupDescription = try? container.decodeIfPresent(String.self, forKey: .mdProductGroupDescription) ?? nil
    //        self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
    //    }
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try Int(container.decode(String.self, forKey: .id))!
            self.name = try container.decode(String.self, forKey: .name)
            self.mdProductGroupDescription = try? container.decodeIfPresent(String.self, forKey: .mdProductGroupDescription) ?? nil
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    init(id: Int,
         name: String,
         mdProductGroupDescription: String? = nil,
         rowCreatedTimestamp: String) {
        self.id = id
        self.name = name
        self.mdProductGroupDescription = mdProductGroupDescription
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias MDProductGroups = [MDProductGroup]
