//
//  MDUserObjectModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.11.26.
//

import Foundation

// MARK: - MDUserObject

/// A record of a user entity (`/objects/userobjects`). Its content lives in the userfields of the entity
/// `userentity-<name>`. Only kept in memory, not in SwiftData.
struct MDUserObject: Codable, Equatable, Identifiable {
    let id: Int
    let userentityID: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userentityID = "userentity_id"
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.userentityID = try container.decodeFlexibleInt(forKey: .userentityID)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(id: Int = -1, userentityID: Int) {
        self.id = id
        self.userentityID = userentityID
    }

    func encode(to encoder: Encoder) throws {
        // Grocy assigns the ID of a new record.
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userentityID, forKey: .userentityID)
    }
}

typealias MDUserObjects = [MDUserObject]

extension MDUserEntity {
    /// The userfield entity that holds this entity's records.
    var userfieldEntity: String { "userentity-\(name)" }
}
