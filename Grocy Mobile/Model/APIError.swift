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

/// True when a request ended because its task was cancelled, for example because the view that started it went away (#167).
/// A cancelled request isn't a failed one, so it shouldn't show an error.
nonisolated func isCancellation(_ error: Error) -> Bool {
    if error is CancellationError {
        return true
    }
    if let urlError = error as? URLError, urlError.code == .cancelled {
        return true
    }
    return false
}
