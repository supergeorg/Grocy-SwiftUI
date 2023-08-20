//
//  MDQuantityUnitsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

// MARK: - MDQuantityUnit

struct MDQuantityUnit: Codable {
    let id: Int
    let name: String
    let namePlural: String
    var active: Bool
    let mdQuantityUnitDescription: String?
    let rowCreatedTimestamp: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case namePlural = "name_plural"
        case active
        case mdQuantityUnitDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            self.name = try container.decode(String.self, forKey: .name)
            self.namePlural = try container.decode(String.self, forKey: .namePlural)
            do {
                self.active = try container.decode(Bool.self, forKey: .active)
            } catch {
                do {
                    self.active = try container.decode(Int.self, forKey: .active) == 1
                } catch {
                    self.active = ["1", "true"].contains(try? container.decode(String.self, forKey: .active))
                }
            }
            self.mdQuantityUnitDescription = try? container.decodeIfPresent(String.self, forKey: .mdQuantityUnitDescription) ?? nil
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int,
        name: String,
        namePlural: String,
        active: Bool,
        mdQuantityUnitDescription: String? = nil,
        rowCreatedTimestamp: String
    ) {
        self.id = id
        self.name = name
        self.namePlural = namePlural
        self.active = active
        self.mdQuantityUnitDescription = mdQuantityUnitDescription
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias MDQuantityUnits = [MDQuantityUnit]
