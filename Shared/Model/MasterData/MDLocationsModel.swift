//
//  MDLocationsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

// MARK: - MDLocation
struct MDLocation: Codable {
    let id: Int
    let name: String
    let mdLocationDescription: String?
    let rowCreatedTimestamp: String
    var isFreezer: Bool
//    let userfields: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id, name
        case mdLocationDescription = "description"
        case rowCreatedTimestamp = "row_created_timestamp"
        case isFreezer = "is_freezer"
//        case userfields
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.mdLocationDescription = try? container.decodeIfPresent(String.self, forKey: .mdLocationDescription) ?? nil
        self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        do {
            let freezerInt = try container.decode(Int.self, forKey: .isFreezer)
            self.isFreezer = freezerInt == 1
        } catch DecodingError.typeMismatch {
            let freezerStr = try container.decode(String.self, forKey: .isFreezer)
            self.isFreezer = freezerStr == "true"
        }
    }
    
    init(id: Int,
         name: String,
         mdLocationDescription: String? = nil,
         rowCreatedTimestamp: String,
         isFreezer: Bool) {
        self.id = id
        self.name = name
        self.mdLocationDescription = mdLocationDescription
        self.rowCreatedTimestamp = rowCreatedTimestamp
        self.isFreezer = isFreezer
    }
}

typealias MDLocations = [MDLocation]

enum IsFreezer: Codable, Equatable {
    case bool(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) {
            self = .bool(x == 1)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .bool(x == "true")
            return
        }
        throw DecodingError.typeMismatch(IsFreezer.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for IsFreezer"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let x):
            try container.encode(x)
        }
    }
}
