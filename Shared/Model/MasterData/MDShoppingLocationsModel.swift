//
//  MDShoppingLocationsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

// MARK: - MDShoppingLocation
struct MDShoppingLocation: Codable {
    let id: Int
    let name: String
    let mdShoppingLocationDescription: String?
    let rowCreatedTimestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case mdShoppingLocationDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
    }
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            self.name = try container.decode(String.self, forKey: .name)
            self.mdShoppingLocationDescription = try? container.decodeIfPresent(String.self, forKey: .mdShoppingLocationDescription) ?? nil
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    init(id: Int,
         name: String,
         mdShoppingLocationDescription: String? = nil,
         rowCreatedTimestamp: String) {
        self.id = id
        self.name = name
        self.mdShoppingLocationDescription = mdShoppingLocationDescription
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias MDShoppingLocations = [MDShoppingLocation]
