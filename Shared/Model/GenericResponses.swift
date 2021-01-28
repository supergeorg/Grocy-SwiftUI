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

// MARK: - SucessfulMessage
struct SucessfulMessage: Codable {
    let createdObjectID: String

    enum CodingKeys: String, CodingKey {
        case createdObjectID = "created_object_id"
    }
}
