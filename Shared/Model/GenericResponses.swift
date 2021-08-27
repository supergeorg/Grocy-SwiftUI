//
//  Errors.swift
//  grocy-ios
//
//  Created by Georg Meissner on 12.10.20.
//

import Foundation

// MARK: - ErrorMessage
struct ErrorMessage: Codable {
    let errorMessage: String

    enum CodingKeys: String, CodingKey {
        case errorMessage = "error_message"
    }
}

// MARK: - SuccessfulCreationMessage
struct SuccessfulCreationMessage: Codable {
    let createdObjectID: Int
    
    enum CodingKeys: String, CodingKey {
        case createdObjectID = "created_object_id"
    }
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.createdObjectID = try container.decode(Int.self, forKey: .createdObjectID) } catch { self.createdObjectID = Int(try container.decode(String.self, forKey: .createdObjectID))! }
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(createdObjectID: Int) {
        self.createdObjectID = createdObjectID
    }
}

// MARK: - SuccessfulPutMessage
struct SuccessfulPutMessage: Codable {
    let changedObjectID: Int
}

// MARK: - SuccessfulActionMessage
struct SuccessfulActionMessage: Codable {
    let responseCode: Int
}

// MARK: - DeleteMessage
struct DeleteMessage: Codable {
    let deletedObjectID: Int

    enum CodingKeys: String, CodingKey {
        case deletedObjectID = "deleted_object_id"
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.deletedObjectID = try container.decode(Int.self, forKey: .deletedObjectID) } catch { self.deletedObjectID = Int(try container.decode(String.self, forKey: .deletedObjectID))! }
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(deletedObjectID: Int) {
        self.deletedObjectID = deletedObjectID
    }
}

