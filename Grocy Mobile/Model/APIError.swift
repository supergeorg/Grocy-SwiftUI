//
//  APIError.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 06.12.25.
//

import Foundation

public enum APIError: Error, Equatable {
    var value: String? {
        return String(describing: self).components(separatedBy: "(").first
    }
    var displayMessage: String {
        if case .errorString(let description) = self {
            return description
        }
        return self.localizedDescription
    }
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        lhs.value == rhs.value
    }
    case internalError
    case serverError(error: Error)
    case serverError(errorMessage: String)
    case encodingError
    case invalidResponse
    case unsuccessful(error: Error)
    case errorString(description: String)
    case timeout
    case invalidEndpoint(endpoint: String)
    case decodingError(error: Error)
    case hassError(error: Error)
    case notLoggedIn(error: Error)
}
