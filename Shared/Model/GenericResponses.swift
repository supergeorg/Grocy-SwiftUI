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
    let createdObjectID: String
    
    enum CodingKeys: String, CodingKey {
        case createdObjectID = "created_object_id"
    }
}

// MARK: - SuccessfulPutMessage
struct SuccessfulPutMessage: Codable {
    let changedObjectID: String
}

// MARK: - SuccessfulActionMessage
struct SuccessfulActionMessage: Codable {
    let responseCode: Int
}

// MARK: - DeleteMessage
struct DeleteMessage: Codable {
    let deletedObjectID: String

    enum CodingKeys: String, CodingKey {
        case deletedObjectID = "deleted_object_id"
    }
}

