//
//  Errors.swift
//  grocy-ios
//
//  Created by Georg Meissner on 12.10.20.
//

import Foundation

struct ErrorMessage: Codable {
    let errorMessage: String

    enum CodingKeys: String, CodingKey {
        case errorMessage = "error_message"
    }
}
