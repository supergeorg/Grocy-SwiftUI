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
    var active: Bool
    let mdProductGroupDescription: String?
    let rowCreatedTimestamp: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case active
        case mdProductGroupDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    init(from decoder: Decoder) throws {
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
            self.mdProductGroupDescription = try? container.decodeIfPresent(String.self, forKey: .mdProductGroupDescription) ?? nil
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int,
        name: String,
        active: Bool,
        mdProductGroupDescription: String? = nil,
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
