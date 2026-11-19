//
//  GrocyPermission.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import Foundation

// MARK: - GrocyPermission

/// One permission of Grocy's permission tree (`/objects/permission_hierarchy`).
///
/// A user with a parent permission also has all its children; `ADMIN` is the root.
/// Fetched on demand for the user management, so it isn't stored in SwiftData.
nonisolated struct GrocyPermission: Codable, Equatable, Identifiable, Sendable {
    var id: Int
    var name: String
    var parent: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, parent
    }

    init(id: Int, name: String, parent: Int? = nil) {
        self.id = id
        self.name = name
        self.parent = parent
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.parent = try container.decodeFlexibleIntIfPresent(forKey: .parent)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
}

typealias GrocyPermissions = [GrocyPermission]

extension GrocyPermissions {
    /// The permissions below `parentID` (the roots for `nil`), sorted by ID like Grocy's permission page.
    func children(of parentID: Int?) -> GrocyPermissions {
        filter { $0.parent == parentID }.sorted { $0.id < $1.id }
    }

    /// The IDs of all permissions below `id`, not including `id` itself.
    func descendantIDs(of id: Int) -> Set<Int> {
        var result = Set<Int>()
        var queue = children(of: id).map(\.id)
        while let next = queue.popLast() {
            guard result.insert(next).inserted else { continue }
            queue += children(of: next).map(\.id)
        }
        return result
    }
}

// MARK: - GrocyUserPermission

/// A permission assigned to a user (`/users/{userId}/permissions`).
nonisolated struct GrocyUserPermission: Codable, Equatable, Sendable {
    var permissionID: Int
    var userID: Int

    enum CodingKeys: String, CodingKey {
        case permissionID = "permission_id"
        case userID = "user_id"
    }

    init(permissionID: Int, userID: Int) {
        self.permissionID = permissionID
        self.userID = userID
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.permissionID = try container.decodeFlexibleInt(forKey: .permissionID)
            self.userID = try container.decodeFlexibleInt(forKey: .userID)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
}

typealias GrocyUserPermissions = [GrocyUserPermission]

/// The body that replaces all permissions of a user.
nonisolated struct GrocyUserPermissionsPUT: Codable, Sendable {
    var permissions: [Int]
}
